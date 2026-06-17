
% Supports multiple classifiers (MCC, PNB, SVM), unit selection (all/perception/memory), shuffled decoding, and TCT analysis

clear; clc; close all;

% Add SVM toolbox path (adjust path as needed)
addpath(genpath('/home/yaojian/Codes/DecodingTool'));

%% ========================== Configurable parameters ==========================
% Experiment configuration ('NoLaser' or 'LaserOnOff')
experiment_type = 'NoLaser'; % 'NoLaser' for pure behavioral training, 'LaserOnOff' for laser on/off experiment
TrialLaserType = 'laseroff';
Group = 'Healthy';
TarReg = 'mPFC';             % Target brain region (e.g., 'mPFC', 'aAIC')
% Core decoding parameters
IsShuffleDecoding = 1;       % 1: shuffled decoding (null distribution), 0: real decoding
DecodingClassifier = 1;      % 1: max_correlation_coefficient_CL (MCC); 2: poisson_naive_bayes_CL (PNB); 3: SVM
UnitCategory = 2;           % Only for NoLaser: 1=all neurons, 2=memory neurons, 3=perception neurons
IsCalculateTCTDecodingResults = 1; % 1: compute temporal cross-training (TCT) results, 0: disable
IsNormalizedData = 1;        % 1: z-score normalize features, 0: no normalization
Num_UnitsForDecoding = 80;   % Number of units to use for decoding
Bin_width = 3;               % Bin width for sliding window (in time bins)
Step_size = 1;               % Step size for sliding window (in time bins)
TimeGain = 10;               % Time gain factor for unit conversion
num_cv_splits = 30;          % Number of cross-validation splits
num_times_to_repeat_each_label_per_cv_split = 2; % Label repetition per CV split
Num_Resample_Runs = 100;     % Number of resampling runs for decoding
WorkerNum = 20;              % Number of parallel workers

% Neuron quality criteria
FRcriteria = 1;              % Minimum firing rate criterion
ISIcriteria = 0.0025;        % Maximum ISI (False Alarm Rate) criterion

% Experiment-specific timing parameters (will be auto-configured based on experiment_type)
BaseLen = [];                % Baseline duration (seconds)
SampleOdorLen = 1;           % Sample odor presentation duration (seconds)
DelayLen = [];               % Delay period duration (seconds)
TestOdorLen = 1;             % Test odor presentation duration (seconds)
ResponseWindowLen = 1;       % Response window duration (seconds)

%% ========================== Auto-configure experiment parameters ==========================
switch experiment_type
    case 'NoLaser'
        homedir = '/home/yaojian/NoLaserinODPA';
        FileSavePath = fullfile(homedir, Group, 'Training');
        BaseLen = 13;
        DelayLen = 10;

    case 'LaserOnOff'
        FileSavePath = '/home/yaojian/LaserActivationOnOffinODPA/Training';
        Phase = 'Training';
        cd(FileSavePath);
        BaseLen = 8;
        DelayLen = 6;

    otherwise
        error('Invalid experiment_type: choose either ''NoLaser'' or ''LaserOnOff''');
end

% Configure null distribution number (10 for shuffle, 1 for real decoding)
if IsShuffleDecoding == 1
    NullDistributionNum = 10;
else
    NullDistributionNum = 1;
end

% Calculate time window parameters
StartTime = BaseLen - 2;
NotComputedLastSecondNum = BaseLen - 2;

%% ========================== Load neuronal spiking data ==========================
% Load units information file
if strcmp(experiment_type, 'NoLaser')
    FileList = dir(fullfile(FileSavePath, '*UnitsInformation*'));
else % LaserOnOff
    FileList = dir(fullfile(FileSavePath, '*UnitsInformation*'));
end
if isempty(FileList)
    error('UnitsInformation file not found in: %s', FileSavePath);
end

UnitsInfo = load(fullfile(FileList.folder, FileList.name));
UnitsInfo = UnitsInfo.UnitsInformation;

% Extract key unit metrics
Reg = UnitsInfo(:, 3);          % Brain region
FR = UnitsInfo(:, 7);           % Mean firing rate
ISI = UnitsInfo(:, 8);          % False Alarm Rate (ISI criterion)

% Filter 1: Target brain region
IsTarReg = cellfun(@(x) contains(x, TarReg), Reg, 'UniformOutput', true);

% Filter 2: Minimum firing rate criterion
IsAboveFRcriteria = cellfun(@(x) x >= FRcriteria, FR, 'UniformOutput', true);

% Filter 3: Maximum ISI criterion
IsAboveISIcriteria = cellfun(@(x) x <= ISIcriteria, ISI, 'UniformOutput', true);

% Filter 4: Unit category selection
if strcmp(experiment_type, 'NoLaser')
    % all/perception/memory units
    switch UnitCategory
        case 1
            IsUnitinCategory = ones(size(UnitsInfo, 1), 1); % All units
        case 2
            % Memory neurons (Transient/Sustained memory-encoding)
            IsUnitinCategory = cellfun(@(x) strcmp(x,'Transient')|strcmp(x,'Sustained'), ...
                UnitsInfo(:, 22), 'UniformOutput', true);
        case 3
            % Perception neurons (significant selectivity in sample odor period)
            IsUnitinCategory = cellfun(@(x) ismember(BaseLen+SampleOdorLen, x), ...
                UnitsInfo(:, 27), 'UniformOutput', true);
    end
else % LaserOnOff
    UnitsSelecDurationType = [];
    for iUnit = 1:size(UnitsInfo, 1)
        UnitsSelecDurationType = [UnitsSelecDurationType; {UnitsInfo{iUnit,22}.(TrialLaserType)}];
    end
    if UnitCategory == 2
        % Memory neurons (Transient/Sustained)
        IsUnitinCategory = cellfun(@(x) strcmp(x,'Transient')|strcmp(x,'Sustained'), ...
            UnitsSelecDurationType, 'UniformOutput', true);
    else
        IsUnitinCategory = ones(size(UnitsInfo, 1), 1); % All units
    end
end
IsUnitSelected = IsTarReg & IsAboveFRcriteria & IsAboveISIcriteria & IsUnitinCategory;

% Apply all filters to units information
UnitsInfo = UnitsInfo(IsUnitSelected, :);
TotalUnitsNum = size(UnitsInfo, 1);

disp('------Step 1: Construct raw data------');

%% ========================== Step 1: Construct and smooth binned firing rate data ==========================
% Calculate sliding window bin start times
if strcmp(experiment_type, 'NoLaser')
    bin_data_len = numel(UnitsInfo{1,12}{1});
else % LaserOnOff
    bin_data_len = numel(UnitsInfo{1,12}.(TrialLaserType){1});
end
the_bin_start_times = 1:Step_size:bin_data_len - Bin_width + 1;

% Initialize variables
AllUnitsTrialNum = zeros(1, TotalUnitsNum);
stimulus_ID = cell(1, TotalUnitsNum);
binned_data = cell(1, TotalUnitsNum);

% Process each unit
for iUnit = 1:TotalUnitsNum
    % Get trial structure and stimulus IDs
    if strcmp(experiment_type,'NoLaser')
        tempTrialStructure = UnitsInfo{iUnit, 10};
        tempFRdata = UnitsInfo{iUnit, 12}; % AllTrialFR
    else
        tempTrialStructure = UnitsInfo{iUnit, 10}.(TrialLaserType);
        tempFRdata = UnitsInfo{iUnit, 12}.(TrialLaserType);
    end

    AllUnitsTrialNum(iUnit) = size(tempTrialStructure, 1);
    stimulus_ID{iUnit} = tempTrialStructure(:, 1); % Sample odor IDs

    % Convert FR cell array to matrix
    tempdata = vertcat(tempFRdata{:});

    % Initialize binned data matrix
    binned_data{iUnit} = zeros(AllUnitsTrialNum(iUnit), numel(the_bin_start_times));

    % Calculate smoothed firing rates for each sliding window
    for iStep = 1:numel(the_bin_start_times)
        bin_range = the_bin_start_times(iStep):(the_bin_start_times(iStep) + Bin_width - 1);
        bin_sum = sum(tempdata(:, bin_range), 2);

        % Normalize based on classifier type
        if DecodingClassifier == 1 || DecodingClassifier == 3 % MCC or SVM
            binned_data{iUnit}(:, iStep) = bin_sum / Bin_width;
        elseif DecodingClassifier == 2 % Poisson Naive Bayes
            binned_data{iUnit}(:, iStep) = bin_sum / TimeGain;
        end
    end
end

% Remove first bin
binned_data = cellfun(@(x) x(:, 2:end), binned_data, 'UniformOutput', false);

%% ========================== Step 2: Create datasource object ==========================
disp('------Step 2: Create datasource object------');
if DecodingClassifier == 2
    % Save PNB-specific binning info
    binned_site_info.binning_parameters.bin_width = Bin_width;
    save_filename = fullfile(FileSavePath,strcat('PNBBinnedData-', TarReg));
    save(save_filename, 'binned_data', 'binned_site_info');

    % Load data as spike counts for PNB classifier
    ds = basic_DS(save_filename, stimulus_ID, num_cv_splits, 1);
else
    % Standard datasource for MCC/SVM
    ds = basic_DS(binned_data, stimulus_ID, num_cv_splits);
end

% Configure datasource parameters
ds.num_times_to_repeat_each_label_per_cv_split = num_times_to_repeat_each_label_per_cv_split;
ds.randomly_shuffle_labels_before_running = IsShuffleDecoding;
ds.sites_to_use = find_sites_with_k_label_repetitions(stimulus_ID, num_cv_splits); % Valid units for CV

%% ========================== Process decoding ==========================
% Ensure unit count does not exceed available units
if Num_UnitsForDecoding >= numel(ds.sites_to_use)
    Num_UnitsForDecoding = numel(ds.sites_to_use) - 1;
end
disp(['------Processing decoding with ' num2str(Num_UnitsForDecoding) ' units------']);

% Create title name (experiment-specific)
if strcmp(experiment_type, 'NoLaser')
    switch UnitCategory
        case 1
            TitleName = [TarReg '-All units-n=' num2str(Num_UnitsForDecoding) '-' Group];
        case 2
            TitleName = [TarReg '-Memory units-n=' num2str(Num_UnitsForDecoding) '-' Group];
        case 3
            TitleName = [TarReg '-Perception units-n=' num2str(Num_UnitsForDecoding) '-' Group];
    end
else % LaserOnOff
    switch UnitCategory
        case 1
            TitleName = [TarReg '-All units-n=' num2str(Num_UnitsForDecoding) '-' TrialLaserType];
        case 2
            TitleName = [TarReg '-Memory units-n=' num2str(Num_UnitsForDecoding) '-' TrialLaserType];
    end
end

% Add shuffle suffix if needed
if IsShuffleDecoding == 1
    TitleName = ['Shuffle-' TitleName];
end

% Configure datasource decoding parameters
PoolSize = numel(ds.sites_to_use);
ds.num_resample_sites = Num_UnitsForDecoding;

% Calculate time period for decoding
BinStart = StartTime * TimeGain + 1;
BinEnd = size(binned_data{1}, 2) - NotComputedLastSecondNum * TimeGain;
ds.time_periods_to_get_data_from = num2cell(BinStart:Step_size:BinEnd);

%% ========================== Step 3: Create feature preprocessor ==========================
disp('------Step 3: Create feature preprocessor object------');
the_feature_preprocessors = {};
if IsNormalizedData == 1
    the_feature_preprocessors{1} = zscore_normalize_FP; % Z-score normalization
end

%% ========================== Step 4: Create classifier object ==========================
disp('------Step 4: Create classifier object------');
switch DecodingClassifier
    case 1
        the_classifier = max_correlation_coefficient_CL;
        Classifier = 'MCC';
    case 2
        the_classifier = poisson_naive_bayes_CL;
        Classifier = 'PNB';
    case 3
        the_classifier = libsvm_CL;
        Classifier = 'SVM';
end

%% ========================== Step 5: Create cross validator ==========================
disp('------Step 5: Create cross validator------');
if DecodingClassifier ~= 2 % MCC/SVM with preprocessing
    the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);
else % PNB (no preprocessing)
    the_cross_validator = standard_resample_CV(ds, the_classifier);
end

% Configure cross-validation parameters
the_cross_validator.num_resample_runs = Num_Resample_Runs;
if IsCalculateTCTDecodingResults == 0
    the_cross_validator.test_only_at_training_times = 1;
end

%% ========================== Step 6: Run Decoding analysis ==========================
disp('------Step 6: Run decoding analysis------');
% Disable progress display
the_cross_validator.display_progress.zero_one_loss = 0;
the_cross_validator.display_progress.resample_run_time = 0;

% Initialize parallel pool
poolobj = gcp('nocreate');
if isempty(poolobj)
    myCluster = parcluster('local');
    myCluster.NumWorkers = WorkerNum;
    parpool(myCluster, WorkerNum);
end

% Run decoding for iterations
for iNullDistr = 1:NullDistributionNum
    if IsShuffleDecoding == 1
        disp(['---Running shuffled decoding iteration ' num2str(iNullDistr) '---']);
    else
        disp(['---Running decoding iteration ' num2str(iNullDistr) '---']);
    end

    % Run decoding (parallel for PDmodel, serial for LaserOnOff - matching original behavior)
    if NullDistributionNum > 1
        f(iNullDistr) = parfeval(@the_cross_validator.run_cv_decoding, 1);
        [~, DECODING_RESULTS] = fetchNext(f);
    else
        DECODING_RESULTS = the_cross_validator.run_cv_decoding;
    end

    % Save results (experiment-specific path)
    save_params = {
        'DECODING_RESULTS', 'binned_data', 'stimulus_ID', 'IsShuffleDecoding', ...
        'Num_Resample_Runs', 'num_cv_splits', 'TitleName', 'tempNum_UnitsForDecoding', ...
        'Classifier', 'Bin_width', 'Step_size', 'SampleOdorLen', 'DelayLen', ...
        'TestOdorLen', 'ResponseWindowLen', 'PoolSize', 'StartTime', 'NotComputedLastSecondNum'
        };

    if strcmp(experiment_type, 'NoLaser')
        save_filename = fullfile(FileSavePath, [
            TitleName '-NullDistributionID-' num2str(iNullDistr) ...
            '-All Parameters-' Classifier
            ]);
    else
        save_filename = fullfile(FileSavePath, [
            TitleName '-NullDistributionID-' num2str(iNullDistr) ...
            '-All Parameters-' Classifier
            ]);
    end

    save(save_filename, save_params{:}, '-v7.3');
end
% Clean up parallel pool
delete(gcp);
disp('------Decoding analysis completed successfully------');