function AllSessionMiceBehavior = SummarizeAllPerfandLick(Data, SummaryMode, TimeID, TimesNum, LickEfficiencyAnaRange, TrialNuminEachWindow, DelayLen, TimeGain, Category)
%% SUMMARIZEALLPERFANDLICK - Aggregate behavioral performance and licking metrics across mice
%   Aggregates hit/miss/false/CR rates, lick efficiency, d-prime, and lick rates for behavioral data
%   across different analysis modes (integration/separation/laser block-based).
%
%   INPUTS:
%       Data:               Cell array of behavioral data structures (1 per mouse)
%       SummaryMode:        Analysis mode (string)
%                           - 'Integration': Aggregate all trials into single metrics
%                           - 'Separation': Split by session/window (time-based)
%                           - 'Block-based laser on off': Split by laser on/off state
%       TimeID:             Time indices for data extraction (used in 'Integration' mode)
%       TimesNum:           Number of time bins (sessions/windows/laser states)
%       LickEfficiencyAnaRange: Lick efficiency analysis time range (cell array, mouse×delay)
%       TrialNuminEachWindow: Number of trials per window (for 'Window' category)
%       DelayLen:           Delay durations (s) e.g., [10;20]
%       TimeGain:           Time scaling factor for lick rate calculation
%       Category:           Data grouping category (string)
%                           - 'Session': Group by experimental session
%                           - 'Window': Group by trial window
%
%   OUTPUTS:
%       AllSessionMiceBehavior: Struct containing aggregated metrics by delay/laser state/time bin
%
%   DEPENDENCIES:
%       CalculateLickEfficiency.m, CalculateDprime.m

%% ====================== 1. Initial validation & setup ======================
% Validate critical inputs
validateInputs(Data, SummaryMode, DelayLen, Category, TimesNum);

% Constants
constants = struct();
constants.LASER_STATES = {'LaserOn','LaserOff'};
constants.PERF_METRICS = {'HitRate','MissRate','FalseRate','CRRate','Perf'};
constants.AGG_METRICS = {'HitRate','MissRate','FalseRate','CRRate','Perf', ...
    'LickEfficiency','Dprime','LickRate_Go','LickRate_Hit',...
    'LickRate_NoGo','LickRate_False'};
constants.OUTCOME_CODES = struct('Hit',1,'Miss',2,'False',3,'CR',4);

% Initialize output structure
AllSessionMiceBehavior = initBehaviorStruct(DelayLen, SummaryMode, TimesNum, constants);
Data = Data(:); % Ensure column vector

%% ====================== 2. Core Logic: Mode-Specific Processing ======================
switch SummaryMode
    case 'Integration'
        AllSessionMiceBehavior = processIntegrationMode(...
            Data, DelayLen, TimeID, Category, TrialNuminEachWindow, ...
            LickEfficiencyAnaRange, TimeGain, constants, AllSessionMiceBehavior);

    case 'Separation'
        AllSessionMiceBehavior = processSeparationMode(...
            Data, DelayLen, Category, TimesNum, TrialNuminEachWindow, ...
            LickEfficiencyAnaRange, TimeGain, constants, AllSessionMiceBehavior);

    case 'Block-based laser on off'
        AllSessionMiceBehavior = processLaserOnOffMode(...
            Data, DelayLen, TimesNum, LickEfficiencyAnaRange, TimeGain, ...
            constants, AllSessionMiceBehavior);

    otherwise
        error('Invalid SummaryMode: %s. Valid modes: Integration/Separation/Block-based laser on off', SummaryMode);
end

end

%% ====================== Input validation ======================
function validateInputs(Data, SummaryMode, DelayLen, Category, TimesNum)
% Validate critical inputs to prevent runtime errors
validModes = {'Integration','Separation','Block-based laser on off'};
if ~ismember(SummaryMode, validModes)
    error('SummaryMode must be one of: %s', strjoin(validModes, '/'));
end

validCategories = {'Session','Window'};
if ~isempty(Category) && ~ismember(Category, validCategories)
    error('Category must be one of: %s', strjoin(validCategories, '/'));
end

if isempty(DelayLen) || ~isnumeric(DelayLen)
    error('DelayLen must be a non-empty numeric array (delay durations in seconds)');
end

if ~iscell(Data) || isempty(Data)
    error('Data must be a non-empty cell array of behavioral data structures');
end

if ~isempty(TimesNum) && (TimesNum < 1 || ~isscalar(TimesNum))
    error('TimesNum must be a positive scalar integer');
end
end

%% ====================== Initialize output structure ======================
function behaviorStruct = initBehaviorStruct(DelayLen, SummaryMode, TimesNum, constants)
% Preallocate output structure with mode-specific fields
behaviorStruct = struct();
nDelays = numel(DelayLen);

for delayIdx = 1:nDelays
    delayVal = DelayLen(delayIdx);
    delayField = sprintf('delay%d', delayVal);
    aggMetrics = constants.AGG_METRICS;

    switch SummaryMode
        case 'Integration'
            % Preallocate numeric arrays (size = nMice × 1 for scalars, nMice × nBins for lick rates)
            fieldVals = struct();
            for metric = 1:numel(aggMetrics)
                fieldVals.(aggMetrics{metric}) = [];
            end
            behaviorStruct.(delayField) = fieldVals;

        case 'Separation'
            % Preallocate cell arrays (1×TimesNum)
            fieldVals = struct();
            for metric = 1:numel(aggMetrics)
                fieldVals.(aggMetrics{metric}) = cell(1, TimesNum);
            end
            behaviorStruct.(delayField) = fieldVals;

        case 'Block-based laser on off'
            % Preallocate cell arrays (1×nLaserStates)
            nLaserStates = numel(constants.LASER_STATES);
            fieldVals = struct();
            for metric = 1:numel(aggMetrics)
                for laserIdx = 1:nLaserStates
                    fieldVals.(aggMetrics{metric}).(constants.LASER_STATES(laserIdx)) = [];
                end
            end
            behaviorStruct.(delayField) = fieldVals;
    end
end
end

%% ====================== Extract trial-related data ======================
function dataOut = extractTrialRelatedData(Data, mouseIdx, DelayLen, TimeID, Category, dataField, trialNumPerWindow)
% Robust extraction of trial/lick data with validation (replaces getTrialRelatedData)
delayField = sprintf('delay%d', DelayLen);
dataOut = [];

% Validate data source existence
if ~isfield(Data{mouseIdx}, 'allSessionBehavior') || ...
        ~isfield(Data{mouseIdx}.allSessionBehavior, delayField) || ...
        ~isfield(Data{mouseIdx}.allSessionBehavior.(delayField), dataField)
    warning('Mouse %d: Missing field %s in delay %d data', mouseIdx, dataField, DelayLen);
    return;
end

dataSource = Data{mouseIdx}.allsessionbehavior.(delayField).(dataField);

switch Category
    case 'Session'
        if TimeID < 1 || TimeID > numel(dataSource)
            warning('Mouse %d: TimeID %d out of range (max: %d)', mouseIdx, TimeID, numel(dataSource));
            return;
        end
        tempData = dataSource(1, TimeID);
        if ~isempty(tempData)
            dataOut = vertcat(tempData{:});
        end

    case 'Window'
        totalData = vertcat(dataSource{:});
        nTrialsNeeded = trialNumPerWindow * numel(TimeID);
        if size(totalData,1) < nTrialsNeeded
            warning('Mouse %d: Insufficient trials (have %d, need %d)', mouseIdx, size(totalData,1), nTrialsNeeded);
            return;
        end

        dataOut = zeros(nTrialsNeeded, size(totalData,2));
        rowIdx = 1;
        for timeIdx = TimeID
            startRow = trialNumPerWindow * (timeIdx - 1) + 1;
            endRow = trialNumPerWindow * timeIdx;
            dataOut(rowIdx:rowIdx+trialNumPerWindow-1, :) = totalData(startRow:endRow, :);
            rowIdx = rowIdx + trialNumPerWindow;
        end
        dataOut = dataOut(1:rowIdx-1, :);
end
end

%% ====================== Calculate core performance metrics ======================
function perfMetrics = calculatePerformanceMetrics(trialOutcome, constants)
perfMetrics = struct();
outcomeCodes = constants.OUTCOME_CODES;

% Count trial types
nHit = nnz(trialOutcome == outcomeCodes.Hit);
nMiss = nnz(trialOutcome == outcomeCodes.Miss);
nFalse = nnz(trialOutcome == outcomeCodes.False);
nCR = nnz(trialOutcome == outcomeCodes.CR);

% Total trials
totalGo = nHit + nMiss;
totalNoGo = nFalse + nCR;
totalTrials = totalGo + totalNoGo;

% Calculate rates (NaN if denominator is zero)
perfMetrics.HitRate = ifelse(totalGo > 0, 100 * nHit / totalGo, NaN);
perfMetrics.MissRate = ifelse(totalGo > 0, 100 * nMiss / totalGo, NaN);
perfMetrics.FalseRate = ifelse(totalNoGo > 0, 100 * nFalse / totalNoGo, NaN);
perfMetrics.CRRate = ifelse(totalNoGo > 0, 100 * nCR / totalNoGo, NaN);
perfMetrics.Perf = ifelse(totalTrials > 0, 100 * (nHit + nCR) / totalTrials, NaN);
end

%% ====================== Calculate licking rates ======================
function lickRates = calculateLickRates(tempLickNum, trialOutcome, TimeGain, constants)
% Calculate lick rates for Go/Hit/NoGo/False trials with NaN handling
lickRates = struct();
outcomeCodes = constants.OUTCOME_CODES;

% Filter lick counts by trial type
maskGo = (trialOutcome == outcomeCodes.Hit) | (trialOutcome == outcomeCodes.Miss);
maskHit = (trialOutcome == outcomeCodes.Hit);
maskNoGo = (trialOutcome == outcomeCodes.False) | (trialOutcome == outcomeCodes.CR);
maskFalse = (trialOutcome == outcomeCodes.False);

% Calculate mean lick rates
lickRates.LickRate_Go = ifelse(nnz(maskGo) > 0, TimeGain * mean(tempLickNum(maskGo, :), 1, 'omitNaN'), NaN);
lickRates.LickRate_Hit = ifelse(nnz(maskHit) > 0, TimeGain * mean(tempLickNum(maskHit, :), 1, 'omitNaN'), NaN);
lickRates.LickRate_NoGo = ifelse(nnz(maskNoGo) > 0, TimeGain * mean(tempLickNum(maskNoGo, :), 1, 'omitNaN'), NaN);
lickRates.LickRate_False = ifelse(nnz(maskFalse) > 0, TimeGain * mean(tempLickNum(maskFalse, :), 1, 'omitNaN'), NaN);
end

%% ====================== Initialize empty cell ======================
function targetStruct = initializeEmptyCell(targetStruct, fieldName, idx)
% Safe initialization of empty cells (replaces initCellIfEmpty)
if ~isfield(targetStruct, fieldName)
    targetStruct.(fieldName) = cell(1, idx);
elseif isempty(targetStruct.(fieldName){idx})
    targetStruct.(fieldName){idx} = [];
end
end

%% ====================== Mode 1: Integration ======================
function AllSessionMiceBehavior = processIntegrationMode(...
    Data, DelayLen, TimeID, Category, TrialNuminEachWindow, LickEfficiencyAnaRange, TimeGain, constants, AllSessionMiceBehavior)

nMice = size(Data, 1);
nDelays = numel(DelayLen);

% Preallocate arrays for performance metrics
for delayIdx = 1:nDelays
    delayVal = DelayLen(delayIdx);
    delayField = sprintf('delay%d', delayVal);
    % Preallocate based on number of mice
    for metric = constants.PERF_METRICS
        AllSessionMiceBehavior.(delayField).(metric{1}) = nan(nMice, 1);
    end
    AllSessionMiceBehavior.(delayField).LickEfficiency = nan(nMice, 1);
    AllSessionMiceBehavior.(delayField).Dprime = nan(nMice, 1);
end

% Process each mouse and delay
for mouseIdx = 1:nMice
    for delayIdx = 1:nDelays
        delayVal = DelayLen(delayIdx);
        delayField = sprintf('delay%d', delayVal);

        % Extract core data
        tempTrialStruct = extractTrialRelatedData(...
            Data, mouseIdx, delayVal, TimeID, Category, 'NewTrialStructure', TrialNuminEachWindow);
        tempLickNum = extractTrialRelatedData(...
            Data, mouseIdx, delayVal, TimeID, Category, 'BinnedLickNum', TrialNuminEachWindow);
        tempLickTs = extractTrialRelatedData(...
            Data, mouseIdx, delayVal, TimeID, Category, 'EachTrialLickTs', TrialNuminEachWindow);

        % Skip if critical data is empty
        if isempty(tempTrialStruct) || isempty(tempLickNum)
            continue;
        end

        % 1. Calculate performance metrics
        trialOutcome = tempTrialStruct(:, end);
        perfMetrics = calculatePerformanceMetrics(trialOutcome, constants);
        for metric = constants.PERF_METRICS
            AllSessionMiceBehavior.(delayField).(metric{1})(mouseIdx) = perfMetrics.(metric{1});
        end

        % 2. Calculate lick rates
        lickRates = calculateLickRates(tempLickNum, trialOutcome, TimeGain, constants);
        for rateMetric = {'LickRate_Go','LickRate_Hit','LickRate_NoGo','LickRate_False'}
            rateName = rateMetric{1};
            if isempty(AllSessionMiceBehavior.(delayField).(rateName))
                AllSessionMiceBehavior.(delayField).(rateName) = nan(nMice, size(lickRates.(rateName),2));
            end
            AllSessionMiceBehavior.(delayField).(rateName)(mouseIdx, :) = lickRates.(rateName);
        end

        % 3. Calculate lick efficiency
        if ~isempty(tempLickTs) && ~isempty(LickEfficiencyAnaRange{mouseIdx, delayIdx})
            maskGo = (trialOutcome == constants.OUTCOME_CODES.Hit) | (trialOutcome == constants.OUTCOME_CODES.Miss);
            maskNoGo = (trialOutcome == constants.OUTCOME_CODES.False) | (trialOutcome == constants.OUTCOME_CODES.CR);
            lickEff = CalculateLickEfficiency(tempLickTs(maskGo,:), tempLickTs(maskNoGo,:), LickEfficiencyAnaRange{mouseIdx, delayIdx});
            AllSessionMiceBehavior.(delayField).LickEfficiency(mouseIdx) = lickEff;
        end

        % 4. Calculate d-prime
        AllSessionMiceBehavior.(delayField).Dprime(mouseIdx) = CalculateDprime(tempTrialStruct);
    end
end
end

%% ====================== Mode 2: Separation (session/window) ======================
function AllSessionMiceBehavior = processSeparationMode(...
    Data, DelayLen, Category, TimesNum, TrialNuminEachWindow, LickEfficiencyAnaRange, TimeGain, constants, AllSessionMiceBehavior)

nMice = size(Data, 1);
nDelays = numel(DelayLen);
perfMetricsList = constants.PERF_METRICS;

for mouseIdx = 1:nMice
    for delayIdx = 1:nDelays
        delayVal = DelayLen(delayIdx);
        delayField = sprintf('delay%d', delayVal);

        % Extract mouse behavior data (validate existence)
        if ~isfield(Data{mouseIdx}.allsessionbehavior, delayField)
            warning('Mouse %d: Missing delay %d data', mouseIdx, delayVal);
            continue;
        end
        mouseBehavior = Data{mouseIdx}.allsessionbehavior.(delayField);

        % Extract core data (pre-concatenate once instead of multiple vertcat)
        tempTrialStruct = vertcat(mouseBehavior.NewTrialStructure{:});
        tempLickNum = vertcat(mouseBehavior.BinnedLickNum{:});
        tempLickTs = vertcat(mouseBehavior.EachTrialLickTs{:});

        % Skip if critical data is empty
        if isempty(tempTrialStruct)
            continue;
        end

        % Extract time-based metrics
        timedMetrics = struct();
        for metric = perfMetricsList
            metricName = metric{1};
            if strcmp(Category, 'Window')
                timedMetrics.(metricName) = horzcat(mouseBehavior.(['Window' metricName]){:});
            elseif strcmp(Category, 'Session')
                timedMetrics.(metricName) = mouseBehavior.(['Sess' metricName]);
            end
        end

        % Skip if metric data is insufficient
        if numel(timedMetrics.HitRate) < TimesNum
            warning('Mouse %d (delay %d): Insufficient %s metrics (have %d, need %d)', ...
                mouseIdx, delayVal, Category, numel(timedMetrics.HitRate), TimesNum);
            continue;
        end

        % Process each time bin
        prevTrialNum = 0;
        trialOutcome = tempTrialStruct(:,7); % Outcome is 7th column

        for timeIdx = 1:TimesNum
            % -------------------- 1. Aggregate performance metrics --------------------
            for metric = perfMetricsList
                metricName = metric{1};
                metricVal = timedMetrics.(metricName)(timeIdx);
                AllSessionMiceBehavior.(delayField).(metricName){timeIdx} = ...
                    [AllSessionMiceBehavior.(delayField).(metricName){timeIdx}; metricVal];
            end

            % -------------------- 2. Create time-bin trial mask --------------------
            timeMask = false(size(tempTrialStruct,1), 1);
            if strcmp(Category, 'Window')
                startRow = TrialNuminEachWindow*(timeIdx-1)+1;
                endRow = TrialNuminEachWindow*timeIdx;
                timeMask(startRow:endRow) = true;
            elseif strcmp(Category, 'Session')
                nTrialThisTime = size(mouseBehavior.NewTrialStructure{timeIdx},1);
                prevTrialNum = prevTrialNum + nTrialThisTime;
                startRow = prevTrialNum - nTrialThisTime + 1;
                endRow = prevTrialNum;
                timeMask(startRow:endRow) = true;
            end

            % -------------------- 3. Calculate lick efficiency --------------------
            maskGo = (trialOutcome == constants.OUTCOME_CODES.Hit | trialOutcome == constants.OUTCOME_CODES.Miss) & timeMask;
            maskNoGo = (trialOutcome == constants.OUTCOME_CODES.False | trialOutcome == constants.OUTCOME_CODES.CR) & timeMask;

            if ~isempty(LickEfficiencyAnaRange{mouseIdx, delayIdx}) && (nnz(maskGo) > 0 || nnz(maskNoGo) > 0)
                lickEff = CalculateLickEfficiency(tempLickTs(maskGo,:), tempLickTs(maskNoGo,:), LickEfficiencyAnaRange{mouseIdx, delayIdx});
                AllSessionMiceBehavior.(delayField).LickEfficiency{timeIdx} = ...
                    [AllSessionMiceBehavior.(delayField).LickEfficiency{timeIdx}; lickEff];
            end

            % -------------------- 4. Calculate d-prime --------------------
            trialRange = find(timeMask);
            if ~isempty(trialRange)
                trialSubset = tempTrialStruct(trialRange, :);
                dprimeVal = CalculateDprime(trialSubset);
                AllSessionMiceBehavior.(delayField).Dprime{timeIdx} = ...
                    [AllSessionMiceBehavior.(delayField).Dprime{timeIdx}; dprimeVal];
            end

            % -------------------- 5. Calculate lick rates --------------------
            lickRates = calculateLickRates(tempLickNum(trialRange,:), trialOutcome(trialRange,:), TimeGain, constants);
            for rateMetric = {'LickRate_Go','LickRate_Hit','LickRate_NoGo','LickRate_False'}
                rateName = rateMetric{1};
                AllSessionMiceBehavior.(delayField).(rateName){timeIdx}(end+1,:) = lickRates.(rateName);
            end
        end
    end
end
end

%% ====================== Mode 3: Block-based laser on/off ======================
function AllSessionMiceBehavior = processLaserOnOffMode(...
    Data, DelayLen, DaysNum, LickEfficiencyAnaRange, TimeGain, constants, AllSessionMiceBehavior)

nMice = size(Data, 1);
nDelays = numel(DelayLen);
nLaserStates = numel(constants.LASER_STATES);
aggMetricsList = constants.AGG_METRICS;

for laserIdx = 1:nLaserStates
    laserState = constants.LASER_STATES{laserIdx};

    for mouseIdx = 1:nMice
        for delayIdx = 1:nDelays
            delayVal = DelayLen(delayIdx);
            delayField = sprintf('delay%d', delayVal);

            % Validate laser state field exists
            if ~isfield(Data{mouseIdx}.allsessionbehavior, delayField) || ...
                    ~isfield(Data{mouseIdx}.allsessionbehavior.(delayField), laserState)
                warning('Mouse %d (delay %d): Missing %s data', mouseIdx, delayVal, laserState);
                continue;
            end
            mouseBehavior = Data{mouseIdx}.allsessionbehavior.(delayField).(laserState);

            % Preallocate daily metrics
            dailyMetrics = initDailyMetrics(DaysNum, mouseBehavior, constants);

            % Collect daily data
            for dayIdx = 1:DaysNum
                % Skip if day data is empty
                if dayIdx > numel(mouseBehavior.NewTrialStructure) || isempty(mouseBehavior.NewTrialStructure{dayIdx})
                    continue;
                end

                % Extract daily trial data
                tempTrialStruct = mouseBehavior.NewTrialStructure{dayIdx};
                trialOutcome = tempTrialStruct(:,7);

                % 1. Collect performance metrics
                for metric = constants.PERF_METRICS
                    metricName = metric{1};
                    sessField = ['Sess' metricName];
                    if isfield(mouseBehavior, sessField) && dayIdx <= numel(mouseBehavior.(sessField))
                        dailyMetrics.(metricName)(dayIdx) = mouseBehavior.(sessField)(dayIdx);
                    end
                end

                % 2. Calculate daily lick efficiency
                lickTs = mouseBehavior.EachTrialLickTs{dayIdx};
                maskGo = (trialOutcome == constants.OUTCOME_CODES.Hit) | (trialOutcome == constants.OUTCOME_CODES.Miss);
                maskNoGo = (trialOutcome == constants.OUTCOME_CODES.False) | (trialOutcome == constants.OUTCOME_CODES.CR);
                dailyMetrics.LickEfficiency(dayIdx) = CalculateLickEfficiency(...
                    lickTs(maskGo,:), lickTs(maskNoGo,:), LickEfficiencyAnaRange{mouseIdx, delayIdx});

                % 3. Calculate daily d-prime
                dailyMetrics.Dprime(dayIdx) = CalculateDprime(tempTrialStruct);

                % 4. Calculate daily lick rates
                lickNum = vertcat(mouseBehavior.BinnedLickNum{dayIdx});
                lickRates = calculateLickRates(lickNum, trialOutcome, TimeGain, constants);
                for rateMetric = {'LickRate_Go','LickRate_Hit','LickRate_NoGo','LickRate_False'}
                    rateName = rateMetric{1};
                    dailyMetrics.(rateName)(dayIdx,:) = lickRates.(rateName);
                end
            end

            % -------------------- Aggregate daily metrics --------------------
            for metric = aggMetricsList
                metricName = metric{1};
                metricVals = dailyMetrics.(metricName);

                if ~isempty(metricVals)
                    meanVal = nanmean(metricVals, 1);
                    AllSessionMiceBehavior.(delayField).(metricName){laserIdx} = ...
                        [AllSessionMiceBehavior.(delayField).(metricName){laserIdx}; meanVal];
                end
            end
        end
    end
end
end

%% ====================== Initialize daily metrics struct ======================
function dailyMetrics = initDailyMetrics(DaysNum, mouseBehavior, constants)

dailyMetrics = struct();

% Performance metrics (1D: DaysNum × 1)
for metric = constants.PERF_METRICS
    dailyMetrics.(metric{1}) = nan(DaysNum, 1);
end

% Lick efficiency and d-prime (1D)
dailyMetrics.LickEfficiency = nan(DaysNum, 1);
dailyMetrics.Dprime = nan(DaysNum, 1);

% Lick rates (2D: DaysNum × nBins)
binCount = size(mouseBehavior.BinnedLickNum{1}, 2);
for rateMetric = {'LickRate_Go','LickRate_Hit','LickRate_NoGo','LickRate_False'}
    dailyMetrics.(rateMetric{1}) = nan(DaysNum, binCount);
end
end

%% ====================== Conditional assignment (NaN-safe) ======================
function out = ifelse(condition, valTrue, valFalse)
% Simple conditional assignment (replaces inline if-else for readability)
if condition
    out = valTrue;
else
    out = valFalse;
end
end