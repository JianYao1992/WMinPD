%% Test significant functional coupling (FC) between simultaneously recorded neurons and determine directionality

clear; clc; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% User Configuration - Set parameters here for different modes //////'No laser' or 'Laser on off' mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
expConfig = struct();
expConfig.CountCriteria = 1000;          % Minimum spike count threshold
expConfig.binsize = '2msbin';            % Time bin size ('2msbin' or '1msbin')
expConfig.thresh = norminv(0.995);       % Bonferroni-corrected significance threshold
expConfig.to_plot = false;               % Generate stem plots for extreme AI values
expConfig.to_save = true;                % Save output statistics
expConfig.NoLaserMode = true;         % 'No laser' or 'Laser on off' mode
expConfig.prefix = 'TestFC';

% Path configuration
if expConfig.NoLaserMode
    expConfig.Group = 'Healthy';
    expConfig.WorkPath = fullfile('/home/yaojian/NoLaserinODPA', expConfig.Group, 'Training');
    expConfig.BinsName = {'Baseline','Sample','1stSecofDelay','2ndSecOfDelay',...
        '3rdSecOfDelay','4thSecOfDelay','5thSecOfDelay','6thSecOfDelay','7thSecOfDelay',...
        '8thSecOfDelay','9thSecOfDelay','10thSecOfDelay','Test','Response'};
else
    expConfig.WorkPath = '/home/yaojian/LaserActivationOnOffinODPA/Training';
    expConfig.BinsName = {'Baseline','Sample','1stSecofDelay','2ndSecOfDelay',...
        '3rdSecOfDelay','4thSecOfDelay','5thSecOfDelay','6thSecOfDelay','Test','Response'};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Analysis Pipeline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process each time bin (from baseline to response)
for iBin = 1:numel(expConfig.BinsName)
    % Setup bin-specific parameters
    CurrBin = expConfig.BinsName{iBin};
    bin_range = [iBin-2, iBin-1];
    BinRange = ['_' num2str(bin_range(1)) '_' num2str(bin_range(2)) '_' expConfig.binsize];

    fprintf('////////// Testing FC for neuronal pairs in [%s] period //////////\n', CurrBin);

    % Load cross-correlation results
    Data = loadCCGData(expConfig, BinRange);

    % Initialize statistics storage
    stats = cell(0);

    % Process each recording session
    for sidx = 1:size(Data.Sums, 1)
        fprintf('///// Processing session %d of %d /////\n', sidx, size(Data.Sums, 1));

        % Extract session metadata
        MiceID = Data.Sums{sidx, 1}(1);
        DayID = Data.Sums{sidx, 1}(2);

        % Process all neuronal pairs (upper triangle only to avoid duplicates)
        stats = processNeuronalPairs(expConfig, Data, sidx, MiceID, DayID, iBin, stats);
    end

    % Save results if enabled
    if expConfig.to_save
        saveResults(expConfig, stats, bin_range);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper Function Definitions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Data = loadCCGData(config, BinRange)
% Load CCG results mat file for current bin
% Inputs:
%   config - Experiment configuration struct
%   BinRange - Time bin range string
% Outputs:
%   Data - Loaded CCG data structure

fprintf('/// Loading xcorr results for [%s] period ///\n', BinRange);
filePattern = fullfile(config.WorkPath, ['*CCGresults*' BinRange '*.mat']);
MatFiles = dir(filePattern);

if isempty(MatFiles)
    error('No CCG files found for bin range: %s', BinRange);
end

Data = load(fullfile(MatFiles.folder, MatFiles.name));
fprintf('********** Finished loading xcorr results **********\n');
end

function stats = processNeuronalPairs(config, Data, SessionID, MiceID, DayID, BinID, stats)
% Process all neuronal pairs for a single session
% Inputs:
%   config - Experiment configuration struct
%   Data - Full CCG dataset
%   sidx - Current session index
%   MiceID/DayID - Session metadata
%   bin_range - Numeric bin range
%   stats - Existing statistics cell array
% Outputs:
%   stats - Updated statistics cell array

% Extract core data based on experiment type
if config.NoLaserMode
    % 'No laser' mode
    xc_base = Data.Sums{SessionID, 6};
else
    % 'Laser on off' mode
    xc_base = Data.Sums{SessionID, 6};
end

% Iterate over all unique neuronal pairs (i < j to avoid duplicates)
numNeurons = size(xc_base.xcorr, 1);
for si = 1:(numNeurons - 1)
    % Get neuron 1 metadata
    su1id = str2double(xc_base.label{si, 1});
    su1_type = getNeuronType(su1id, Data, SessionID, config);

    for sj = (si + 1):numNeurons
        % Get neuron 2 metadata
        su2id = str2double(xc_base.label{sj, 1});
        su2_type = getNeuronType(su2id, Data, SessionID, config);

        % Calculate total spike counts
        countData = calculateSpikeCounts(si, sj, Data, SessionID, config);

        % Skip low-count pairs
        if isLowCountPair(countData, config)
            onepair = createBasicPairStruct(MiceID, DayID, si, sj, su1id, su2id, ...
                su1_type, su2_type, countData, Data.Sums(SessionID,:), config);
            stats{end+1} = onepair;
            clear onepair;
            continue;
        end

        % Calculate asymmetry index (AI) for pairs with significant FC
        aiData = AsymmetryIndexInDifferentConditions(si, sj, Data.Sums(SessionID,:), countData, config);

        % Create full pair structure with AI data
        onepair = createFullPairStruct(MiceID, DayID, si, sj, su1id, su2id, ...
            su1_type, su2_type, countData, aiData, Data.Sums(SessionID,:), config);

        % Generate plots for extreme AI values if enabled
        if config.to_plot
            plotAI(SessionID, BinID, onepair, aiData, xc_base, config);
        end

        stats{end+1} = onepair;
        clear onepair;
    end
end
end

function neuronType = getNeuronType(id, Data, sessionid, config)
% Classify neuron type (Sustained/Transient/Nonmemory)
% Inputs:
%   suid - Neuron cluster ID
%   Data - Full dataset
%   sidx - Session index
%   config - Experiment config
% Outputs:
%   neuronType - Struct with type classification (laser-specific if needed)

if config.NoLaserMode
    % 'No laser' mode
    neuronType = classifySingleNeuronType(id, Data.Sums{sessionid, 3}, Data.Sums{sessionid, 4});
else
    % 'Laser on off' mode
    neuronType.laseroff = classifySingleNeuronType(id, Data.Sums{sessionid, 3}.laseroff, Data.Sums{sessionid, 4}.laseroff);
    neuronType.laseron  = classifySingleNeuronType(id, Data.Sums{sessionid, 3}.laseron,  Data.Sums{sessionid, 4}.laseron);
end
end

function type = classifySingleNeuronType(id, SustainedNeuronsList, TransientNeuronsList)
% Helper for single-condition neuron classification
if ismember(id, SustainedNeuronsList)
    type = 'Sustained';
elseif ismember(id, TransientNeuronsList)
    type = 'Transient';
else
    type = 'Nonmemory';
end
end

function countData = calculateSpikeCounts(si, sj, Data, sidx, config)
% Calculate total spike counts for neuronal pair
% Outputs:
%   countData - Struct with total counts

if config.NoLaserMode
    % 'No laser' mode
    countData.totalCounts1 = nansum(squeeze(Data.Sums{sidx, 6}.xcorr(si, sj, :)));
    countData.totalCounts2 = nansum(squeeze(Data.Sums{sidx, 8}.xcorr(si, sj, :)));
else
    % 'Laser on off' mode
    countData.totalCounts1_laseroff = nansum(squeeze(Data.Sums{sidx, 6}.xcorr(si, sj, :)));
    countData.totalCounts2_laseroff = nansum(squeeze(Data.Sums{sidx, 8}.xcorr(si, sj, :)));
    countData.totalCounts1_laseron  = nansum(squeeze(Data.Sums{sidx, 10}.xcorr(si, sj, :)));
    countData.totalCounts2_laseron  = nansum(squeeze(Data.Sums{sidx, 12}.xcorr(si, sj, :)));
end
end

function isLow = isLowCountPair(countData, config)
% Check if pair has insufficient spike counts
if config.NoLaserMode
    isLow = (countData.totalCounts1 < config.CountCriteria) && ...
        (countData.totalCounts2 < config.CountCriteria);
else
    isLow = (countData.totalCounts1_laseroff < config.CountCriteria) && ...
        (countData.totalCounts2_laseroff < config.CountCriteria) && ...
        (countData.totalCounts1_laseron < config.CountCriteria) && ...
        (countData.totalCounts2_laseron < config.CountCriteria);
end
end

function AIvalue = AsymmetryIndexInDifferentConditions(Neuron1IDinSession, Neuron2IDinSession, IndividualSessionResult, countData, config)
% Calculate Asymmetry Index (AI)
% Outputs:
%   AIvalue - Struct with AI values and significance flags

AIvalue = struct();
binParams = getBinParameters(config.binsize);

if config.NoLaserMode
    AIvalue.s1 = computeAI(Neuron1IDinSession, Neuron2IDinSession, IndividualSessionResult{6}, IndividualSessionResult{7}, ...
        countData.totalCounts1, config.CountCriteria, config.thresh, binParams);
    AIvalue.s2 = computeAI(Neuron1IDinSession, Neuron2IDinSession, IndividualSessionResult{8}, IndividualSessionResult{9}, ...
        countData.totalCounts2, config.CountCriteria, config.thresh, binParams);
else
    % Laser off conditions
    AIvalue.laseroff.s1 = computeAI(Neuron1IDinSession, Neuron2IDinSession, IndividualSessionResult{6}, IndividualSessionResult{7}, ...
        countData.totalCounts1_laseroff, config.CountCriteria, config.thresh, binParams);
    AIvalue.laseroff.s2 = computeAI(Neuron1IDinSession, Neuron2IDinSession, IndividualSessionResult{8}, IndividualSessionResult{9}, ...
        countData.totalCounts2_laseroff, config.CountCriteria, config.thresh, binParams);

    % Laser on conditions
    AIvalue.laseron.s1 = computeAI(Neuron1IDinSession, Neuron2IDinSession, IndividualSessionResult{10}, IndividualSessionResult{11}, ...
        countData.totalCounts1_laseron, config.CountCriteria, config.thresh, binParams);
    AIvalue.laseron.s2 = computeAI(Neuron1IDinSession, Neuron2IDinSession, IndividualSessionResult{12}, IndividualSessionResult{13}, ...
        countData.totalCounts2_laseron, config.CountCriteria, config.thresh, binParams);
end
end

function binParams = getBinParameters(binsize)
% Get bin-specific parameters for AI calculation
if strcmp(binsize, '2msbin')
    binParams.zeroBin = 50:51;
    binParams.scoreRange = 46:55;
elseif strcmp(binsize, '1msbin')
    binParams.zeroBin = 99:102;
    binParams.scoreRange = 96:105;
else
    error('Unsupported bin size: %s', binsize);
end
end

function result = computeAI(Neuron1IDinSession, Neuron2IDinSession, xc, xshuf, totalCounts, CountCriteria, threshold, binParams)
% Compute AI for a single condition/session/pair
% Outputs:
%   result - Struct with AI value, significance, and raw data

result = struct('AI', 0, 'significant', false);

if totalCounts < CountCriteria
    return;
end

% Extract and process cross-correlation data
hists = squeeze(xc.xcorr(Neuron1IDinSession, Neuron2IDinSession, :));
shufs = squeeze(xshuf.shiftpredictor(Neuron1IDinSession, Neuron2IDinSession, :));
stdShuf = std(shufs);
diffs = hists - smooth(shufs);

% Zero out central bin
diffs(binParams.zeroBin) = 0;

% Calculate z-scores
scores = diffs(binParams.scoreRange) ./ stdShuf;
result.significant = any(scores > threshold);
result.hists = hists;
result.shufs = shufs;
result.diffs = diffs;
result.scores = scores;
result.stds = stdShuf;

% Calculate AI if significant
if result.significant
    bincounts = diffs(binParams.scoreRange);
    bincounts(scores <= threshold) = 0;

    % Split into pre- and post-central bins
    mid = numel(bincounts)/2;
    sumLeft = sum(bincounts(1:mid));
    sumRight = sum(bincounts(mid+1:end));
    total = sumLeft + sumRight;

    if total == 0
        result.AI = 0;
    else
        result.AI = (sumLeft - sumRight) / total;
    end
end
end

function onepair = createBasicPairStruct(MiceID, DayID, Neuon1IDinSession, Neuron2IDinSession, Neuron1ID, Neuron2ID, ...
    su1_type, su2_type, countData, IndividualSessionResult, config)
% Create basic pair structure (for low-count pairs)
onepair = struct();
onepair.mouseid = MiceID;
onepair.learningdayid = DayID;
onepair.su1_label_idx = Neuon1IDinSession;
onepair.su2_label_idx = Neuron2IDinSession;
onepair.su1_clusterid = Neuron1ID;
onepair.su2_clusterid = Neuron2ID;

% Neuron type classification
if config.NoLaserMode
    onepair.su1_sel_type = su1_type;
    onepair.su2_sel_type = su2_type;
    onepair.totalcounts1 = countData.totalCounts1;
    onepair.totalcounts2 = countData.totalCounts2;
else
    onepair.su1_sel_type.laseroff = su1_type.laseroff;
    onepair.su1_sel_type.laseron = su1_type.laseron;
    onepair.su2_sel_type.laseroff = su2_type.laseroff;
    onepair.su2_sel_type.laseron = su2_type.laseron;

    % Count data
    onepair.totalcounts1.laseroff = countData.totalCounts1_laseroff;
    onepair.totalcounts2.laseroff = countData.totalCounts2_laseroff;
    onepair.totalcounts1.laseron = countData.totalCounts1_laseron;
    onepair.totalcounts2.laseron = countData.totalCounts2_laseron;
end

% Basic neuron metadata
onepair = addNeuronMetadata(onepair, IndividualSessionResult, Neuon1IDinSession, Neuron2IDinSession, config);
end

function onepair = createFullPairStruct(MiceID, DayID, Neuron1IDinSession, Neuron2IDinSession, Neuron1ID, Neuron2ID, ...
    su1_type, su2_type, countData, AIresult, IndividualSessionResult, config)

% Create full pair structure with AI data
onepair = createBasicPairStruct(MiceID, DayID, Neuron1IDinSession, Neuron2IDinSession, Neuron1ID, Neuron2ID, ...
    su1_type, su2_type, countData, IndividualSessionResult, config);

% Add AI data
if config.NoLaserMode
    onepair.s1_peak_significant = AIresult.s1.significant;
    onepair.s2_peak_significant = AIresult.s2.significant;
    onepair.AIs1 = AIresult.s1.AI;
    onepair.AIs2 = AIresult.s2.AI;

    if AIresult.s1.significant
        onepair.hists1 = AIresult.s1.hists;
        onepair.shufs1 = AIresult.s1.shufs;
        onepair.diffs1 = AIresult.s1.diffs;
    end
    if AIresult.s2.significant
        onepair.hists2 = AIresult.s2.hists;
        onepair.shufs2 = AIresult.s2.shufs;
        onepair.diffs2 = AIresult.s2.diffs;
    end
else
    % Laser off
    onepair.s1_peak_significant.laseroff = AIresult.laseroff.s1.significant;
    onepair.s2_peak_significant.laseroff = AIresult.laseroff.s2.significant;
    onepair.AIs1.laseroff = AIresult.laseroff.s1.AI;
    onepair.AIs2.laseroff = AIresult.laseroff.s2.AI;

    % Laser on
    onepair.s1_peak_significant.laseron = AIresult.laseron.s1.significant;
    onepair.s2_peak_significant.laseron = AIresult.laseron.s2.significant;
    onepair.AIs1.laseron = AIresult.laseron.s1.AI;
    onepair.AIs2.laseron = AIresult.laseron.s2.AI;

    % Raw data for laser conditions
    if AIresult.laseroff.s1.significant
        onepair.hists1.laseroff = AIresult.laseroff.s1.hists;
        onepair.shufs1.laseroff = AIresult.laseroff.s1.shufs;
        onepair.diffs1.laseroff = AIresult.laseroff.s1.diffs;
    end
    if AIresult.laseroff.s2.significant
        onepair.hists2.laseroff = AIresult.laseroff.s2.hists;
        onepair.shufs2.laseroff = AIresult.laseroff.s2.shufs;
        onepair.diffs2.laseroff = AIresult.laseroff.s2.diffs;
    end
    if AIresult.laseron.s1.significant
        onepair.hists1.laseron = AIresult.laseron.s1.hists;
        onepair.shufs1.laseron = AIresult.laseron.s1.shufs;
        onepair.diffs1.laseron = AIresult.laseron.s1.diffs;
    end
    if AIresult.laseron.s2.significant
        onepair.hists2.laseron = AIresult.laseron.s2.hists;
        onepair.shufs2.laseron = AIresult.laseron.s2.shufs;
        onepair.diffs2.laseron = AIresult.laseron.s2.diffs;
    end
end
end

function onepair = addNeuronMetadata(onepair, individualsessionresult, Neuron1IDinSession, Neuron2IDinSession, config)

if config.NoLaserMode
    xc_s1 = individualsessionresult{6};
    xc_s2 = individualsessionresult{8};

    % Waveform and firing rate metadata
    onepair.wf_stats_su1 = xc_s1.label{Neuron1IDinSession, 2};
    onepair.wf_stats_su2 = xc_s1.label{Neuron2IDinSession, 2};
    onepair.wf_su1 = xc_s1.label{Neuron1IDinSession, 3};        % Waveform data
    onepair.wf_su2 = xc_s1.label{Neuron2IDinSession, 3};

    % Preferred sample and firing rates
    onepair.prefered_sample_su1 = xc_s1.label{Neuron1IDinSession, 4};
    onepair.prefered_sample_su2 = xc_s1.label{Neuron2IDinSession, 4};
    onepair.FRs1trials_su1 = xc_s1.label{Neuron1IDinSession, 5}; % S1 trial FR
    onepair.FRs2trials_su1 = xc_s1.label{Neuron1IDinSession, 6}; % S2 trial FR
    onepair.FRs1trials_su2 = xc_s1.label{Neuron2IDinSession, 5};
    onepair.FRs2trials_su2 = xc_s1.label{Neuron2IDinSession, 6};

    % Trial ID
    onepair.s1_trials = xc_s1.cfg.trials;
    onepair.s2_trials = xc_s2.cfg.trials;

    % Recording region
    onepair.reg_su1 = xc_s1.label{Neuron1IDinSession, 7};
    onepair.reg_su2 = xc_s1.label{Neuron2IDinSession, 7};
else
    xc_s1_laseroff = individualsessionresult{6};
    xc_s2_laseroff = individualsessionresult{8};
    xc_s1_laseron = individualsessionresult{10};
    xc_s2_laseron = individualsessionresult{12};

    onepair.wf_stats_su1 = xc_s1_laseroff.label{Neuron1IDinSession,2};
    onepair.wf_stats_su2 = xc_s1_laseroff.label{Neuron2IDinSession,2};
    onepair.wf_su1 = xc_s1_laseroff.label{Neuron1IDinSession,3};
    onepair.wf_su2 = xc_s1_laseroff.label{Neuron2IDinSession,3};

    onepair.prefered_sample_su1.laseroff = xc_s1_laseroff.label{Neuron1IDinSession, 4};
    onepair.prefered_sample_su2.laseroff = xc_s1_laseroff.label{Neuron2IDinSession, 4};
    onepair.prefered_sample_su1.laseron = xc_s1_laseron.label{Neuron1IDinSession, 4};
    onepair.prefered_sample_su2.laseron = xc_s1_laseron.label{Neuron2IDinSession, 4};
    onepair.FRs1trials_su1.laseroff = xc_s1_laseroff.label{Neuron1IDinSession,5};
    onepair.FRs2trials_su1.laseroff = xc_s1_laseroff.label{Neuron1IDinSession,6};
    onepair.FRs1trials_su2.laseroff = xc_s1_laseroff.label{Neuron2IDinSession,5};
    onepair.FRs2trials_su2.laseroff = xc_s1_laseroff.label{Neuron2IDinSession,6};
    onepair.FRs1trials_su1.laseron = xc_s1_laseron.label{Neuron1IDinSession,5};
    onepair.FRs2trials_su1.laseron = xc_s1_laseron.label{Neuron1IDinSession,6};
    onepair.FRs1trials_su2.laseron = xc_s1_laseron.label{Neuron2IDinSession,5};
    onepair.FRs2trials_su2.laseron = xc_s1_laseron.label{Neuron2IDinSession,6};

    onepair.s1_trials.laseroff = xc_s1_laseroff.cfg.trials;
    onepair.s2_trials.laseroff = xc_s2_laseroff.cfg.trials;
    onepair.s1_trials.laseron = xc_s1_laseron.cfg.trials;
    onepair.s2_trials.laseron = xc_s2_laseron.cfg.trials;

    onepair.reg_su1 = xc_s1_laseroff.label{Neuron1IDinSession, 7};
    onepair.reg_su2 = xc_s1_laseroff.label{Neuron2IDinSession, 7};
end
end

function plotAI(SessionID, BinID, onepair, aiData, xc, config)
% Generate stem plots for neuron pairs with |AI| ≥ 0.9
binParams = getBinParameters(config.binsize);
figPos = [100, 100, 600, 800];
threshAI = 0.9;
su1 = onepair.su1_clusterid;
su2 = onepair.su2_clusterid;
idLabel = sprintf('%d, %d', su1, su2);
workDir = config.WorkPath;
noLaser = config.NoLaserMode;

% Check sample matching condition
sampleValid = (onepair.prefered_sample_su1(BinID+1) > 0 && onepair.prefered_sample_su2(BinID+1) > 0) ...
    && (onepair.prefered_sample_su1(BinID+1) == onepair.prefered_sample_su2(BinID+1));

% Pre-check AI threshold pass status for each laser state
if noLaser
    passOff = abs(onepair.AIs1) >= threshAI || abs(onepair.AIs2) >= threshAI;
    passOn  = false;
else
    passOff = abs(onepair.AIs1.laseroff) >= threshAI || abs(onepair.AIs2.laseroff) >= threshAI;
    passOn  = abs(onepair.AIs1.laseron) >= threshAI || abs(onepair.AIs2.laseron) >= threshAI;
end

% Early exit if no valid data to plot
if ~sampleValid || (~passOff && ~passOn)
    return;
end

%% Plot LaserOff figure
if passOff
    fh = figure('Color','w','Position',figPos,'Renderer','Painters');
    if noLaser
        drawS1 = abs(onepair.AIs1) >= threshAI;
        drawS2 = abs(onepair.AIs2) >= threshAI;
        if drawS1
            plotContextData(xc, onepair.hists1, onepair.shufs1, onepair.diffs1, ...
                aiData.s1.scores, config.thresh, binParams, 1);
        end
        if drawS2
            plotContextData(xc, onepair.hists2, onepair.shufs2, onepair.diffs2, ...
                aiData.s2.scores, config.thresh, binParams, 2);
        end
    else
        drawS1 = abs(onepair.AIs1.laseroff) >= threshAI;
        drawS2 = abs(onepair.AIs2.laseron) >= threshAI;
        if drawS1
            plotContextData(xc, onepair.hists1.laseroff, onepair.shufs1.laseroff, ...
                onepair.diffs1.laseroff, aiData.laseroff.s1.scores, config.thresh, binParams, 1);
        end
        if drawS2
            plotContextData(xc, onepair.hists2.laseroff, onepair.shufs2.laseroff, ...
                onepair.diffs2.laseroff, aiData.laseroff.s2.scores, config.thresh, binParams, 2);
        end
    end
    text(0, 0.3, idLabel);
    fname = sprintf('xcorr_showcase_%d_%d_%d_Laseroff', SessionID, su1, su2);
    saveas(fh, fullfile(workDir, fname), 'fig');
    close(fh);
end

%% Plot LaserOn figure (only for laser-enabled mode)
if ~noLaser && passOn
    fh = figure('Color','w','Position',figPos,'Renderer','Painters');
    drawS1 = abs(onepair.AIs1.laseron) >= threshAI;
    drawS2 = abs(onepair.AIs2.laseron) >= threshAI;
    if drawS1
        plotContextData(xc, onepair.hists1.laseron, onepair.shufs1.laseron, ...
            onepair.diffs1.laseron, aiData.laseron.s1.scores, config.thresh, binParams, 1);
    end
    if drawS2
        plotContextData(xc, onepair.hists2.laseron, onepair.shufs2.laseron, ...
            onepair.diffs2.laseron, aiData.laseron.s2.scores, config.thresh, binParams, 2);
    end
    text(0, 0.3, idLabel);
    fname = sprintf('xcorr_showcase_%d_%d_%d_Laseron', SessionID, su1, su2);
    saveas(fh, fullfile(workDir, fname), 'fig');
    close(fh);
end

end

function plotContextData(xc, hists, shufs, diffs, scores, thresh, binParams, contextNum)
% Plot cross-correlogram, shift predictor, and z-score for a single context
colOffset = (contextNum - 1) * 2;

% Cross-correlogram (raw counts)
subplot(3, 2, 1 + colOffset); hold on;
stem(xc.time(binParams.zeroBin)*1000, hists(binParams.zeroBin), ...
    'Marker','none','LineWidth',15,'Color',[0.8,0.8,0.8]);
stem(xc.time(setdiff(binParams.scoreRange, binParams.zeroBin))*1000, ...
    hists(setdiff(binParams.scoreRange, binParams.zeroBin)), ...
    'Marker','none','LineWidth',15);
title('Cross-Correlogram');
xlabel('Time (ms)');
ylabel('Spike-Pair Count');

% Shift predictor (shuffled data)
subplot(3, 2, 3 + colOffset); hold on;
stem(xc.time(binParams.zeroBin)*1000, shufs(binParams.zeroBin), ...
    'Marker','none','LineWidth',15,'Color',[0.8,0.8,0.8]);
stem(xc.time(setdiff(binParams.scoreRange, binParams.zeroBin))*1000, ...
    shufs(setdiff(binParams.scoreRange, binParams.zeroBin)), ...
    'Marker','none','LineWidth',15);
plot(xc.time(binParams.scoreRange)*1000, smooth(shufs(binParams.scoreRange)), ...
    '-r','LineWidth',1.5);
title('Shift Predictor');
xlabel('Time (ms)');
ylabel('Spike-Pair Count');

% Significant peaks (z-scores)
subplot(3, 2, 5 + colOffset); hold on;
sigbin = find(scores > thresh);
insigbin = find(scores <= thresh);

stem(xc.time(binParams.scoreRange(insigbin))*1000, ...
    diffs(binParams.scoreRange(insigbin))/std(shufs), ...
    'Marker','none','LineWidth',15,'Color',[0.8,0.8,0.8]);
stem(xc.time(binParams.scoreRange(sigbin))*1000, ...
    diffs(binParams.scoreRange(sigbin))/std(shufs), ...
    'Marker','none','LineWidth',15);
yline(thresh, '--r');
title('Significant Peaks (Z-Score)');
xlabel('Time (ms)');
ylabel('FN normalized spike count');
end

function saveResults(config, stats, bin_range)
tic;
if config.NoLaserMode
    filename = sprintf('%s_XCORR_stats_%d_%d_%s_%s.mat', ...
        config.prefix, bin_range(1), bin_range(2), config.binsize, config.Group);
else
    filename = sprintf('%s_XCORR_stats_%d_%d_%s_LaserOnOff.mat', ...
        config.prefix, bin_range(1), bin_range(2), config.binsize);
end
save(fullfile(config.WorkPath, filename), 'stats', 'bin_range', '-v7.3');
saveTime = toc;

fprintf('******************** File saved: %s (%.1f seconds) ********************\n', ...
    filename, saveTime);
end