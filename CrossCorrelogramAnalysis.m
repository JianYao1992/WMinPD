%% Cross-Correlogram Analysis for Neuronal Pairs

clear; clc; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -------------------------- CONFIGURATION -------------------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Analysis type selection ('PDmodel' or 'LaserOnOff')
analysis_type = 'No laser'; % Change to 'Laser on off' for laser analysis
group = 'PDmodel';

% Quality thresholds
FR_THRESHOLD = 1;             % Firing rate threshold (spikes/s)
FA_THRESHOLD = 0.0025;        % False alarm rate threshold
MONO_CONN_CRITERIA = '10ms'; % '10ms' (2ms bins) or '5ms' (1ms bins)

% Bin size configuration
if strcmp(MONO_CONN_CRITERIA, '10ms')
    binsize = '2msbin';
    cfg_binsize = 0.002; % 2ms in seconds
elseif strcmp(MONO_CONN_CRITERIA, '5ms')
    binsize = '1msbin';
    cfg_binsize = 0.001; % 1ms in seconds
end

% Path configuration
switch analysis_type
    case 'No laser'
        homedir = '/home/yaojian/NoLaserinODPA';
        % Time segment lengths (seconds)
        BefSampOdorLen = 13;
        SampOdorLen = 1;
        DelayLen = 10;
        TestOdorLen = 1;
        RespWindLen = 1;

    case 'Laser on off'
        homedir = '/home/yaojian/LaserActivationOnOffinODPA/Training';
        % Time segment lengths (seconds)
        BefSampOdorLen = 8;
        SampOdorLen = 1;
        DelayLen = 6;
        TestOdorLen = 1;
        RespWindLen = 1;
end
bin_indices = -1:1:SampOdorLen+DelayLen+TestOdorLen;

TimeGain = 10; % Time gain for second-based FR calculation
addpath(genpath('/home/yaojian/Codes/fieldtrip-20200326')); % Add FieldTrip path

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -------------------------- DATA LOADING -------------------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('//////////////////// Loading units information ////////////////////\n');

% Load unit information based on analysis type
switch analysis_type
    case 'No laser'
        units_file = fullfile(homedir, group, 'Training', strcat('UnitsInformation_', group, '.mat'));

    case 'Laser on off'
        units_file = fullfile(homedir, 'UnitsInformation_LaserOnOff.mat');
end

Units = load(units_file);
UnitsInformation = Units.UnitsInformation;

% Add unit ID column (last column)
UnitsInformation = [UnitsInformation, num2cell((1:size(UnitsInformation,1))')];
fprintf('//////////////////// Loading units information finished ////////////////////\n');
% In 'cell' matrix of 36 columns, from left to right, they are 1{MiceID}, 2{DayID}, 3{Region}, 4{UnitID}, 5{SikeTime}, 6{Waveform}, 7{Mean firing rate}, 8{FalseAlarmRate},
% 9{SignalNoiseRatio}, 10{TrialMarker}, 11{AllTrialSpikeRg}, 12{AllTrialFR}, 13{LaserTrialSpikeRg}, 14{LaserTrialFR}, 15{AllTrialLickRg}, 16{AllTrialLickRate}, 17{S1TrialsFR},
% 18{S2TrialsFR}, 19{S1TrialsNormalizedFR}, 20{S2TrialsNormalizedFR}, 21{selectivity and shuffled value, 2X1 cell matrix}, 22{sustained, transient memory-coding, or non-memory},
% 23{Selectivity consistence type}, 24{selectivity significance pattern}, 25{Zstat and P, 1X2 cell matrix}, 26{significant selectivity value}, 27{significant selectivity bin ID},
% 28{delay selective duration}, 29{s1- or s2-preferred and FR modulation type (relative to baseline period)}, 30{HitTrialsFR, 1X2 cell matrix}, 31{MissTrialsFR, 1X2 cell matrix},
% 32{FATrialsFR, 1X2 cell matrix}, 33{CRTrialsFR, 1X2 cell matrix}, 34{Second-based auROC for sample odors}, 35{second-based PEV for sample odors}, 36{second-based mutual information for sample odors}, respectively.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---------------------- HIGH-QUALITY UNIT SELECTION ------------------------- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract quality metrics and filter high-quality units
UnitsFR = cell2mat(UnitsInformation(:,7));  % Mean firing rate
UnitsFA = cell2mat(UnitsInformation(:,8));  % False alarm rate
HighQualityUnits = UnitsInformation(UnitsFR >= FR_THRESHOLD & UnitsFA <= FA_THRESHOLD, :);

% Extract session identifiers (MouseID + DayID)
startIdx_mice = regexp(HighQualityUnits{1,1}, '\d', 'once');
startIdx_day = regexp(HighQualityUnits{1,2}, '\d', 'once');

% Mouse ID processing
MouseID = cell2mat(HighQualityUnits(:,1));
MouseID = str2num(MouseID(:,startIdx_mice:end));
UniqMouseID = unique(MouseID);

% Day ID processing
DayID = cell2mat(HighQualityUnits(:,2));
DayID = str2num(DayID(:,startIdx_day:end));
UniqDayID = unique(DayID);

% Create all possible session combinations
[UniqMouseID, UniqDayID] = meshgrid(UniqMouseID, UniqDayID);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --------------------- CROSS-CORRELOGRAM CALCULATION ------------------- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iBin = bin_indices
    bin_range = [iBin, iBin+1]; % Time bin for analysis
    Sums = []; % Store results for current bin

    % Process each session
    for iSess = 1:numel(UniqMouseID)
        % Get current session IDs
        currMouseID = UniqMouseID(iSess);
        currDayID = UniqDayID(iSess);

        % Filter units for current session
        sessUnits = HighQualityUnits(MouseID == currMouseID & DayID == currDayID, :);

        % Only process sessions with ≥2 units
        if size(sessUnits, 1) >= 2
            switch analysis_type
                case 'No laser'
                    [xc_results] = processNoLaserTask(sessUnits, bin_range, BefSampOdorLen, SampOdorLen, DelayLen, TestOdorLen, RespWindLen, TimeGain, cfg_binsize);

                case 'Laser on off'
                    [xc_results] = processLaserOnOffTask(sessUnits, bin_range, BefSampOdorLen, SampOdorLen, DelayLen, TestOdorLen, RespWindLen, TimeGain, cfg_binsize);
            end

            % Compile session results
            tempsums = compileResults(currMouseID, currDayID, units_file, xc_results, analysis_type);
            Sums = [Sums; tempsums];
        end

        % Progress update
        fprintf('******************** CCG finished: session %d/%d for bin [%d %d] ********************\n',...
            iSess, numel(UniqMouseID), bin_range(1), bin_range(end));
    end

    % Save results for current bin
    saveResults(Sums, homedir, analysis_type, bin_range, binsize, group);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -------------------------- FUNCTIONS --------------------------- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [xc_results] = processNoLaserTask(Units, bin_range, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindowLen, TimeGain, binsize)
% Create spikeTrials structure
spikeTrials = createSpikeTrialsStruct(Units, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindowLen);

% Calculate cross-correlograms
[xc_s1, xcshuf_s1, xc_s2, xcshuf_s2] = calculateXCorr(spikeTrials, bin_range, binsize);

% Get unit classification (sustained/transient/non-memory)
[SustainedID, TransientID, NonmemoryID] = getUnitClassification(Units, 'No laser');

% Calculate second-based firing rates
updateUnitLabels(Units, xc_s1, TimeGain, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindowLen, 'No laser');

% Package results
xc_results = struct(...
    'sustained', SustainedID,...
    'transient', TransientID,...
    'nonmemory', NonmemoryID,...
    'xc_s1', xc_s1,...
    'xcshuf_s1', xcshuf_s1,...
    'xc_s2', xc_s2,...
    'xcshuf_s2', xcshuf_s2);
end

function [xc_results] = processLaserOnOffTask(Units, bin_range, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindowLen, TimeGain, cfg_binsize)
% Create laser on/off spikeTrials structures
[spikeTrials_off, spikeTrials_on] = createLaserSpikeTrialsStruct(Units, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindowLen);

% Calculate cross-correlograms for laser off/on
[xc_s1_off, xcshuf_s1_off, xc_s2_off, xcshuf_s2_off] = calculateXCorr(spikeTrials_off, bin_range, cfg_binsize);
[xc_s1_on, xcshuf_s1_on, xc_s2_on, xcshuf_s2_on] = calculateXCorr(spikeTrials_on, bin_range, cfg_binsize);

% Get unit classification for laser off/on
[SustainedID, TransientID, NonmemoryID] = getUnitClassification(Units, 'LaserOnOff');

% Calculate second-based firing rates for laser off/on
updateUnitLabels(Units, xc_s1_off, TimeGain, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindowLen, 'Laser off');
updateUnitLabels(Units, xc_s1_on, TimeGain, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindowLen, 'Laser on');

% Package results
xc_results = struct(...
    'sustained', SustainedID,...
    'transient', TransientID,...
    'nonmemory', NonmemoryID,...
    'xc_s1_off', xc_s1_off,...
    'xcshuf_s1_off', xcshuf_s1_off,...
    'xc_s2_off', xc_s2_off,...
    'xcshuf_s2_off', xcshuf_s2_off,...
    'xc_s1_on', xc_s1_on,...
    'xcshuf_s1_on', xcshuf_s1_on,...
    'xc_s2_on', xc_s2_on,...
    'xcshuf_s2_on', xcshuf_s2_on);
end

function spikeTrials = createSpikeTrialsStruct(Units, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindowLen)
spikeTrials = struct('label', [], 'trialinfo', [], 'trialtime', [], 'trial', [], 'time', []);
spikeTrials.trialinfo = Units{1,10};
trialtime_end = SampleOdorLen + DelayLen + TestOdorLen + RespWindowLen;
spikeTrials.trialtime = repmat([-1*BaselineLen, trialtime_end], size(spikeTrials.trialinfo, 1), 1);

% Populate spike data for each unit
for iUnit = 1:size(Units, 1)
    spikeTrials.label{iUnit,1} = num2str(Units{iUnit,37});
    [temptrial, temptime] = extractSpikeTimes(Units, iUnit, BaselineLen, 'PDmodel');
    spikeTrials.trial = [spikeTrials.trial {temptrial}];
    spikeTrials.time = [spikeTrials.time {temptime}];
end
end

function [spikeTrials_off, spikeTrials_on] = createLaserSpikeTrialsStruct(Units, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindowLen)
% Initialize structures
spikeTrials_off = struct('label', [], 'trialinfo', [], 'trialtime', [], 'trial', [], 'time', []);
spikeTrials_on = struct('label', [], 'trialinfo', [], 'trialtime', [], 'trial', [], 'time', []);

% Trial info
spikeTrials_off.trialinfo = Units{1,10}.laseroff;
spikeTrials_on.trialinfo = Units{1,10}.laseron;

% Trial time ranges
trialtime_end = SampleOdorLen + DelayLen + TestOdorLen + RespWindowLen;
spikeTrials_off.trialtime = repmat([-1*BaselineLen, trialtime_end], size(spikeTrials_off.trialinfo, 1), 1);
spikeTrials_on.trialtime = repmat([-1*BaselineLen, trialtime_end], size(spikeTrials_on.trialinfo, 1), 1);

% Populate spike data for each unit
for iUnit = 1:size(Units, 1)
    % Laser off
    spikeTrials_off.label{iUnit,1} = num2str(Units{iUnit,37});
    [temptrial_off, temptime_off] = extractSpikeTimes(Units, iUnit, BaselineLen, 'LaserOff');
    spikeTrials_off.trial = [spikeTrials_off.trial {temptrial_off}];
    spikeTrials_off.time = [spikeTrials_off.time {temptime_off}];

    % Laser on
    spikeTrials_on.label{iUnit,1} = num2str(Units{iUnit,37});
    [temptrial_on, temptime_on] = extractSpikeTimes(Units, iUnit, BaselineLen, 'LaserOn');
    spikeTrials_on.trial = [spikeTrials_on.trial {temptrial_on}];
    spikeTrials_on.time = [spikeTrials_on.time {temptime_on}];
end
end

function [trial, time] = extractSpikeTimes(Units, iUnit, BaselineLen, trial_type)
trial = [];
time = [];

switch trial_type
    case 'No laser'
        spike_data = Units{iUnit,11};
        num_trials = size(spike_data, 2);

        for iTrial = 1:num_trials
            trial_spikes = spike_data{1,iTrial};
            trial = [trial, iTrial*ones(1, size(trial_spikes, 2))];
            time = [time, trial_spikes - BaselineLen];
        end
    
    case 'Laser off'
        spike_data = Units{iUnit,11}.laseroff;
        num_trials = size(spike_data, 2);

        for iTrial = 1:num_trials
            trial_spikes = spike_data{1,iTrial};
            trial = [trial, iTrial*ones(1, size(trial_spikes, 2))];
            time = [time, trial_spikes - BaselineLen];
        end

    case 'Laser on'
        spike_data = Units{iUnit,11}.laseron;
        num_trials = size(spike_data, 2);

        for iTrial = 1:num_trials
            trial_spikes = spike_data{1,iTrial};
            trial = [trial, iTrial*ones(1, size(trial_spikes, 2))];
            time = [time, trial_spikes - BaselineLen];
        end

end
end

function [xc_s1, xcshuf_s1, xc_s2, xcshuf_s2] = calculateXCorr(spikeTrials, bin_range, cfg_binsize)
% Configure FieldTrip xcorr parameters
cfg = [];
cfg.maxlag = 0.1;             % 100 ms maximum lag
cfg.binsize = cfg_binsize;    % Bin size (2ms/1ms)
cfg.outputunit = 'raw';       % Raw count output
cfg.latency = bin_range;      % Analysis time window
cfg.vartriallen = 'no';       % Fixed trial lengths
cfg.debias = 'no';            % No debiasing

% Context 1 trials (S1)
cfg.trials = find(spikeTrials.trialinfo(:,1)==1);
if numel(cfg.trials) < 2
    xc_s1 = [];
    xcshuf_s1 = [];
else
    cfg.method = 'xcorr';
    xc_s1 = ft_spike_xcorr(cfg, spikeTrials);
    cfg.method = 'shiftpredictor';
    xcshuf_s1 = ft_spike_xcorr(cfg, spikeTrials);
end

% Context 2 trials (S2)
cfg.trials = find(spikeTrials.trialinfo(:,1)==2);
if numel(cfg.trials) < 2
    xc_s2 = [];
    xcshuf_s2 = [];
else
    cfg.method = 'xcorr';
    xc_s2 = ft_spike_xcorr(cfg, spikeTrials);
    cfg.method = 'shiftpredictor';
    xcshuf_s2 = ft_spike_xcorr(cfg, spikeTrials);
end
end

function [SustainedUnitsID, TransientUnitsID, NonmemoryUnitsID] = getUnitClassification(Units, analysis_type)
SustainedUnitsID = [];
TransientUnitsID = [];
NonmemoryUnitsID = [];

for iUnit = 1:size(Units, 1)
    switch analysis_type
        case 'No laser'
            unit_type = Units{iUnit,22};

        case 'Laser on off'
            % Initialize struct for laser conditions
            if ~isstruct(SustainedUnitsID)
                SustainedUnitsID = struct('laseroff', [], 'laseron', []);
                TransientUnitsID = struct('laseroff', [], 'laseron', []);
                NonmemoryUnitsID = struct('laseroff', [], 'laseron', []);
            end

            unit_type_off = Units{iUnit,22}.laseroff;
            unit_type_on = Units{iUnit,22}.laseron;

            % Laser off classification
            if strcmp(unit_type_off, 'Sustained')
                SustainedUnitsID.laseroff = [SustainedUnitsID.laseroff, Units{iUnit,37}];
            elseif strcmp(unit_type_off, 'Transient')
                TransientUnitsID.laseroff = [TransientUnitsID.laseroff, Units{iUnit,37}];
            elseif strcmp(unit_type_off, 'Non-memory')
                NonmemoryUnitsID.laseroff = [NonmemoryUnitsID.laseroff, Units{iUnit,37}];
            end

            % Laser on classification
            if strcmp(unit_type_on, 'Sustained')
                SustainedUnitsID.laseron = [SustainedUnitsID.laseron, Units{iUnit,37}];
            elseif strcmp(unit_type_on, 'Transient')
                TransientUnitsID.laseron = [TransientUnitsID.laseron, Units{iUnit,37}];
            elseif strcmp(unit_type_on, 'Non-memory')
                NonmemoryUnitsID.laseron = [NonmemoryUnitsID.laseron, Units{iUnit,37}];
            end

            continue; % Skip "No laser" logic for laser analysis
    end

    % "No laser" classification logic
    if strcmp(unit_type, 'Sustained')
        SustainedUnitsID = [SustainedUnitsID, Units{iUnit,37}];
    elseif strcmp(unit_type, 'Transient')
        TransientUnitsID = [TransientUnitsID, Units{iUnit,37}];
    elseif strcmp(unit_type, 'Non-memory')
        NonmemoryUnitsID = [NonmemoryUnitsID, Units{iUnit,37}];
    end
end
end

function updateUnitLabels(Units, xcresult, TimeGain, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindLen, trial_type)
for iUnit = 1:size(Units, 1)
    % Initialize label fields
    xcresult.label{iUnit,2} = []; % Waveform stats
    xcresult.label{iUnit,3} = []; % Waveform voltage
    xcresult.label{iUnit,7} = Units{iUnit,3}; % Brain region
    % Sample preference
    time_window = BaselineLen : BaselineLen + SampleOdorLen + DelayLen + TestOdorLen;
    % Calculate second-based firing rates for S1/S2
    [s1_fr, s2_fr] = calculateSecondBasedFR(Units, iUnit, TimeGain, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindLen, trial_type);
    switch trial_type
        case 'No laser'
            xcresult.label{iUnit,4} = Units{iUnit,24}(time_window);
            xcresult.label{iUnit,5} = s1_fr; % S1 FR
            xcresult.label{iUnit,6} = s2_fr; % S2 FR
        case 'Laser off'
            xcresult.label{iUnit,4} = Units{iUnit,24}.laseroff(time_window);
            xcresult.label{iUnit,5} = s1_fr; % S1 FR
            xcresult.label{iUnit,6} = s2_fr; % S2 FR
        case 'Laser on'
            xcresult.label{iUnit,4} = Units{iUnit,24}.laseron(time_window);
            xcresult.label{iUnit,5} = s1_fr; % S1 FR
            xcresult.label{iUnit,6} = s2_fr; % S2 FR
    end


end
end

function [s1_fr, s2_fr] = calculateSecondBasedFR(Units, iUnit, TimeGain, BaselineLen, SampleOdorLen, DelayLen, TestOdorLen, RespWindowLen, trial_type)
% Extract raw FR data
switch trial_type
    case 'No laser'
        fr_s1_raw = Units{iUnit,17};
        fr_s2_raw = Units{iUnit,18};

    case 'Laser off'
        fr_s1_raw = Units{iUnit,17}.laseroff;
        fr_s2_raw = Units{iUnit,18}.laseroff;

    case 'Laser on'
        fr_s1_raw = Units{iUnit,17}.laseron;
        fr_s2_raw = Units{iUnit,18}.laseron;
end

% Calculate second-based mean FR
s1_fr = [];
s2_fr = [];
num_seconds = floor(size(fr_s1_raw, 2)/TimeGain);

for iSec = 1:num_seconds
    time_window = 2 + TimeGain*(iSec-1) : 1 + TimeGain*iSec;
    s1_fr = [s1_fr, mean(mean(fr_s1_raw(:, time_window)))];
    s2_fr = [s2_fr, mean(mean(fr_s2_raw(:, time_window)))];
end

% Apply time window filter
time_window = BaselineLen : BaselineLen + SampleOdorLen + DelayLen + TestOdorLen + RespWindowLen;
s1_fr = s1_fr(:, time_window);
s2_fr = s2_fr(:, time_window);
end

function results = compileResults(MouseID, DayID, units_file, xc_results, analysis_type)
switch analysis_type
    case 'No laser'
        results = {
            [MouseID, DayID],...
            units_file,...
            xc_results.sustained,...
            xc_results.transient,...
            xc_results.nonmemory,...
            xc_results.xc_s1,...
            xc_results.xcshuf_s1,...
            xc_results.xc_s2,...
            xc_results.xcshuf_s2
            };

    case 'Laser on off'
        results = {
            [MouseID, DayID],...
            units_file,...
            xc_results.sustained,...
            xc_results.transient,...
            xc_results.nonmemory,...
            xc_results.xc_s1_off,...
            xc_results.xcshuf_s1_off,...
            xc_results.xc_s2_off,...
            xc_results.xcshuf_s2_off,...
            xc_results.xc_s1_on,...
            xc_results.xcshuf_s1_on,...
            xc_results.xc_s2_on,...
            xc_results.xcshuf_s2_on
            };
end
end

function saveResults(Sums, homedir, analysis_type, bin_range, binsize, group)
tic;
switch analysis_type
    case 'No laser'
        save_path = fullfile(homedir, group, 'Training',...
            sprintf('CCGresults_%d_%d_%s_%s.mat', bin_range(1), bin_range(end), binsize, group));

    case 'Laser on off'
        save_path = fullfile(homedir,...
            sprintf('CCGresults_%d_%d_%s_LaserOnOff_SNCA.mat', bin_range(1), bin_range(end), binsize));
end

save(save_path, 'Sums', '-v7.3');
save_time = toc;

fprintf('******************** File: %s saved taking %.1f seconds ********************\n',...
    save_path, save_time);
end