%% Extract FC pairs over the time course of the trial

clear; clc; close all;

%% ===================== CONFIGURATION =====================
% Experiment type selection: 'No Laser' or 'Laser on off'
expType = 'No laser';
Group = 'PDmodel';

% Shared parameters
binsize = '2msbin';
TarReg = {'mPFC-mPFC','aAIC-aAIC','mPFC-aAIC','aAIC-mPFC'};

% Experiment-specific parameters
if strcmp(expType, 'No laser')
    SecondNum = 14;
    basePath = fullfile('/home/yaojian/NoLaserinODPA', Group, 'Training');
    hasLaserConditions = false; % No laser conditions
    fileSuffix = ['_' Group]; % Add group suffix to filenames
elseif strcmp(expType, 'Laser on off')
    SecondNum = 10;
    basePath = '/home/yaojian/LaserActivationOnOffinODPA/Training';
    hasLaserConditions = true; % Laser on/off conditions exist
    fileSuffix = '_LaserOnOff'; % No group suffix for laser files
end

%% ===================== INITIALIZATION =====================
% Initialize FC structure with appropriate fields
if ~hasLaserConditions
    fc = struct(...
        'mPFCmPFC', struct('FcPairOfEachSec_s1', [], 'FcPairOfEachSec_s2', [], 'PairOfEachSec', []), ...
        'aAICaAIC', struct('FcPairOfEachSec_s1', [], 'FcPairOfEachSec_s2', [], 'PairOfEachSec', []), ...
        'mPFCaAIC', struct('FcPairOfEachSec_s1', [], 'FcPairOfEachSec_s2', [], 'PairOfEachSec', []), ...
        'aAICmPFC', struct('FcPairOfEachSec_s1', [], 'FcPairOfEachSec_s2', [], 'PairOfEachSec', []));
else
    fc = struct(...
        'mPFCmPFC', struct('FcPairOfEachSec_s1', struct('laseroff', [], 'laseron', []), ...
                          'FcPairOfEachSec_s2', struct('laseroff', [], 'laseron', []), ...
                          'PairOfEachSec', []), ...
        'aAICaAIC', struct('FcPairOfEachSec_s1', struct('laseroff', [], 'laseron', []), ...
                          'FcPairOfEachSec_s2', struct('laseroff', [], 'laseron', []), ...
                          'PairOfEachSec', []), ...
        'mPFCaAIC', struct('FcPairOfEachSec_s1', struct('laseroff', [], 'laseron', []), ...
                          'FcPairOfEachSec_s2', struct('laseroff', [], 'laseron', []), ...
                          'PairOfEachSec', []), ...
        'aAICmPFC', struct('FcPairOfEachSec_s1', struct('laseroff', [], 'laseron', []), ...
                          'FcPairOfEachSec_s2', struct('laseroff', [], 'laseron', []), ...
                          'PairOfEachSec', []));
end

%% ===================== PROCESS TARGET REGIONS =====================
for iReg = 1:numel(TarReg)
    fprintf('//////////Processing %s statistics//////////\n', TarReg{iReg});
    
    % Load initial stats file to identify target neuron pairs
    statsFile = fullfile(basePath, sprintf('TestFC_XCORR_stats_-1_0_%s%s.mat', binsize, fileSuffix));
    statsData = load(statsFile);
    stats = statsData.stats;
    
    % Identify target pairs based on region
    IsTarPair = identifyTargetPairs(stats, TarReg{iReg});
    TarPairID = find(IsTarPair == 1);
    clearvars statsData stats;
    
    % Process each time bin
    data = processTimeBins(basePath, binsize, fileSuffix, SecondNum, TarPairID, TarReg{iReg}, hasLaserConditions);
    
    % Assign processed data to appropriate FC structure field
    switch TarReg{iReg}
        case 'mPFC-mPFC'
            fc.mPFCmPFC = data;
        case 'aAIC-aAIC'
            fc.aAICaAIC = data;
        case 'mPFC-aAIC'
            fc.mPFCaAIC = data;
        case 'aAIC-mPFC'
            fc.aAICmPFC = data;
    end
end

%% ===================== SAVE RESULTS =====================
saveFile = fullfile(basePath, sprintf('FC_IndividualDetail_%s%s.mat', binsize, fileSuffix));
save(saveFile, 'fc', '-v7.3');
fprintf('Analysis complete. Results saved to: %s\n', saveFile);

%% ===================== HELPER FUNCTIONS =====================
function IsTarPair = identifyTargetPairs(stats, targetRegion)
    % Identifies which neuron pairs belong to the target region
    % Inputs:
    %   stats - Statistics structure array
    %   targetRegion - Target region string (e.g., 'mPFC-mPFC')
    % Output:
    %   IsTarPair - Logical array indicating target pairs
    
    IsTarPair = [];
    for iPair = 1:numel(stats)
        reg1 = stats{iPair}.reg_su1;
        reg2 = stats{iPair}.reg_su2;
        tempIsTarPair = 0;
        
        switch targetRegion
            case 'mPFC-mPFC'
                if (strcmp(reg1, 'left mPFC') && strcmp(reg2, 'left mPFC')) || ...
                   (strcmp(reg1, 'right mPFC') && strcmp(reg2, 'right mPFC'))
                    tempIsTarPair = 1;
                end
            case 'aAIC-aAIC'
                if (strcmp(reg1, 'left aAIC') && strcmp(reg2, 'left aAIC')) || ...
                   (strcmp(reg1, 'right aAIC') && strcmp(reg2, 'right aAIC'))
                    tempIsTarPair = 1;
                end
            case {'mPFC-aAIC', 'aAIC-mPFC'}
                if (strcmp(reg1, 'left mPFC') && strcmp(reg2, 'left aAIC')) || ...
                   (strcmp(reg1, 'right mPFC') && strcmp(reg2, 'right aAIC')) || ...
                   (strcmp(reg1, 'left aAIC') && strcmp(reg2, 'left mPFC')) || ...
                   (strcmp(reg1, 'right aAIC') && strcmp(reg2, 'right mPFC'))
                    tempIsTarPair = 1;
                end
        end
        IsTarPair = [IsTarPair, tempIsTarPair];
    end
end

function data = processTimeBins(Path, BinSize, FileSuffix, SecondNumber, TargetPairID, TargetRegion, hasLaserConditions)
    % Processes each time bin to extract FC pairs
    % Inputs:
    %   Path - directory for data files
    %   BinSize - Bin size string
    %   FileSuffix - Suffix for filenames
    %   SecondNumber - Number of time bins to process
    %   TargetPairID - Indices of target neuron pairs
    %   TargetRegion - Target region string
    %   hasLaserConditions - Boolean for laser on/off conditions
    % Output:
    %   data - Processed FC data structure
    
    % Initialize data structure
    data = struct();
    if ~hasLaserConditions
        [data.FcPairOfEachSec_s1, data.FcPairOfEachSec_s2, data.PairOfEachSec] = deal(cell(1, SecondNumber));
    else
        [data.FcPairOfEachSec_s1.laseroff, data.FcPairOfEachSec_s1.laseron, ...
            data.FcPairOfEachSec_s2.laseroff, data.FcPairOfEachSec_s2.laseron, ...
            data.PairOfEachSec] = deal(cell(1, SecondNumber));
    end

    % Process each time bin
    for iBin = 1:SecondNumber
        fprintf('///Processing bin [%d %d] FC statistics///\n', iBin-2, iBin-1);
        
        % Load bin-specific stats
        binFile = fullfile(Path, sprintf('TestFC_XCORR_stats_%d_%d_%s%s.mat', ...
            iBin-2, iBin-1, BinSize, FileSuffix));
        binData = load(binFile);
        stats = binData.stats;
        tempstats = stats(:, TargetPairID);
        data.PairOfEachSec{iBin} = tempstats;
        
        % Initialize empty cell arrays for current bin
        if ~hasLaserConditions
            data.FcPairOfEachSec_s1{iBin} = cell(0);
            data.FcPairOfEachSec_s2{iBin} = cell(0);
        else
            data.FcPairOfEachSec_s1.laseroff{iBin} = cell(0);
            data.FcPairOfEachSec_s1.laseron{iBin} = cell(0);
            data.FcPairOfEachSec_s2.laseroff{iBin} = cell(0);
            data.FcPairOfEachSec_s2.laseron{iBin} = cell(0);
        end

        % Process each neuron pair in current bin
        for iPair = 1:numel(tempstats)
            processSinglePair(data, tempstats{iPair}, TargetRegion, iBin, hasLaserConditions);
        end
        
        clearvars binData stats tempstats;
    end
end

function processSinglePair(data, pairStats, TargetRegion, BinID, hasLaserConditions)
% Process a single neuron pair's statistics
% Inputs:
%   data - Main data structure to populate
%   pairStats - Statistics for single neuron pair
%   targetRegion - Target region string
%   BinID - Current time bin index
%   hasLaserConditions - Boolean for laser on/off conditions

reg1 = pairStats.reg_su1;
reg2 = pairStats.reg_su2;

if ~hasLaserConditions
    % Process S1
    if isfield(pairStats, 'AIs1')
        val = pairStats.AIs1;
        if isSignificantPair(val, TargetRegion, reg1, reg2)
            data.FcPairOfEachSec_s1{BinID}{end+1} = pairStats;
        end
    end

    % Process S2
    if isfield(pairStats, 'AIs2')
        val = pairStats.AIs2;
        if isSignificantPair(val, TargetRegion, reg1, reg2)
            data.FcPairOfEachSec_s2{BinID}{end+1} = pairStats;
        end
    end
else
    % Process S1 (laser off)
    if isfield(pairStats, 'AIs1') && isfield(pairStats.AIs1, 'laseroff')
        val = pairStats.AIs1.laseroff;
        if isSignificantPair(val, TargetRegion, reg1, reg2)
            data.FcPairOfEachSec_s1.laseroff{BinID}{end+1} = pairStats;
        end
    end

    % Process S2 (laser off)
    if isfield(pairStats, 'AIs2') && isfield(pairStats.AIs2, 'laseroff')
        val = pairStats.AIs2.laseroff;
        if isSignificantPair(val, TargetRegion, reg1, reg2)
            data.FcPairOfEachSec_s2.laseroff{BinID}{end+1} = pairStats;
        end
    end

    % Process S1 (laser on)
    if isfield(pairStats, 'AIs1') && isfield(pairStats.AIs1, 'laseron')
        val = pairStats.AIs1.laseron;
        if isSignificantPair(val, TargetRegion, reg1, reg2)
            data.FcPairOfEachSec_s1.laseron{BinID}{end+1} = pairStats;
        end
    end

    % Process S2 (laser on)
    if isfield(pairStats, 'AIs2') && isfield(pairStats.AIs2, 'laseron')
        val = pairStats.AIs2.laseron;
        if isSignificantPair(val, TargetRegion, reg1, reg2)
            data.FcPairOfEachSec_s2.laseron{BinID}{end+1} = pairStats;
        end
    end
end
end

function IsSignificant = isSignificantPair(value, TargetRegion, reg1, reg2)
    % Determines if a neuron pair is statistically significant
    % Inputs:
    %   value - AI value to test
    %   TargetRegion - Target region string
    %   reg1/reg2 - Region names for the pair
    % Output:
    %   isSignificant - Boolean indicating significance
    
    IsSignificant = false;
    
    switch TargetRegion
        case 'mPFC-aAIC'
            if ((contains(reg1, 'mPFC') && contains(reg2, 'aAIC') && value > 0) || ...
                (contains(reg1, 'aAIC') && contains(reg2, 'mPFC') && value < 0))
                IsSignificant = true;
            end
        case 'aAIC-mPFC'
            if ((contains(reg1, 'aAIC') && contains(reg2, 'mPFC') && value > 0) || ...
                (contains(reg1, 'mPFC') && contains(reg2, 'aAIC') && value < 0))
                IsSignificant = true;
            end
        case {'mPFC-mPFC', 'aAIC-aAIC'}
            if value ~= 0
                IsSignificant = true;
            end
    end
end