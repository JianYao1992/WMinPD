%% Behavioral data analysis
% 1. Mode 1: Single 10s delay (S1/S2 → T1/T2)
% 2. Mode 2: Dual-delay standard (10s/20s, S1/S2 → T1/T2)
% 3. Mode 3: Dual-delay pseudo-delay (10s/20s, S1-S4 → T1/T2)


clear; clc; close all;
filesavepath = cd;

%% ====================== Centralized Parameter Configuration ======================
% 1. Mode & Laser configuration (only modify here for mode switch)
cfg.Mode = 1;                  % 1=Single 10s | 2=Dual-delay standard | 3=Dual-delay pseudo
cfg.IsLaserOnOff = 0;          % 0=No laser split | 1=Split by LaserOn/LaserOff
cfg.LaserStates = {'LaserOn','LaserOff'};

% 2. Universal experimental constants (shared by all modes)
cfg.Const = struct(...
    'HitRateThres', 50,...    % Hit rate threshold (%) for excluding unmotivated trials
'BaseLen', 4,...              % Baseline duration (s)
'SampOdorLen', 1,...          % Sample odor duration (s)
'TestOdorLen', 1,...          % Test odor duration (s)
'TestRespInterval', 0,...     % Post-test response interval (s)
'RespWindowLen', 1,...        % Response window duration (s)
'AfterTrial', 4,...           % Post-trial duration (s)
'LickThres', 31,...           % Lick interval threshold (ms, filter false triggers)
'OutcomeMarkers', [7,6,4,5],... % Outcome markers (row3): Hit=7 | Miss=6 | FA=4 | CR=5
'OutcomeTypeMap', [1,2,3,4],... % Standardized outcome codes: Hit=1 | Miss=2 | FA=3 | CR=4
'OutcomeMarkerToCode', containers.Map([7,6,4,5],[1,2,3,4])... % Map for quick conversion
);

% 3. Number of trial and window (laser-dependent)
if cfg.IsLaserOnOff == 0
    cfg.MaxTrialsNum = 192;    % Total trials (Mode1=192; Mode2/3=96/delay)
    cfg.MaxWindowNum = 8;      % Windows for performance calculation
else
    cfg.MaxTrialsNum = 96;
    cfg.MaxWindowNum = 3;
end

% 4. Mode-Specific Parameters
cfg.ModeParams = getModeSpecificParams(cfg.Mode, cfg.Const.SampOdorLen);

% ====================== Parameter Validation ======================
validateConfig(cfg);

%% ====================== Data Loading & Initialization ======================
% Load .ser files
serFiles = dir(fullfile(filesavepath, '*.ser'));
fileNum = length(serFiles);
if fileNum == 0
    error('No .ser files found in current directory: %s', filesavepath);
end

% Extract mouse ID from path
[parentPath, mouseID, ~] = fileparts(filesavepath);
if isempty(mouseID)
    mouseID = 'UnknownMouse'; % Fallback for invalid path
end

% Initialize all-session behavior structure
allSessionBehavior = initBehaviorStruct(cfg, fileNum);

%% ====================== Batch process each .ser file ======================
for fileIndex = 1:fileNum
    % Load file
    fileName = serFiles(fileIndex).name;
    filePath = fullfile(filesavepath, fileName);
    fprintf('Processing file (%d/%d): %s\n', fileIndex, fileNum, fileName);

    try
        % Convert .ser to numeric matrix
        data = double(ser2mat(filePath));

        % Step 1: Extract core events (samples/tests/outcomes/licks/laser)
        events = extractCoreEvents(data, cfg);
        if isempty(events.SampStartStamp) || isempty(events.TestStartStamp) || isempty(events.Outcome)
            warning('Skipping %s: Insufficient valid events (samples/tests/outcomes)', fileName);
            continue;
        end

        % Step 2: Standardize timestamps (convert to seconds, align to origin)
        events = standardizeTimestamps(events);

        % Step 3: Align samples → tests → outcomes (clean invalid trials)
        alignedTrials = alignTrialEvents(events, cfg);
        if isempty(alignedTrials.TrialStructure)
            warning('Skipping %s: No valid aligned trials', fileName);
            continue;
        end

        % Step 4: Calculate performance & process licking data
        behavior = processTrialBehavior(alignedTrials, events.LickTime, cfg);

        % Step 5: Update all-session structure
        allSessionBehavior = updateAllSessionStruct(allSessionBehavior, behavior, cfg, fileIndex);

        % Step 6: Save per-file behavior data
        savePerFileData(behavior, filesavepath, mouseID, fileName);

    catch ME
        warning('Failed to process %s: %s', fileName, ME.message);
        continue;
    end
end

% Save aggregated all-session data
save(fullfile(parentPath, [mouseID '_AllDaysBehavior.mat']), 'allSessionBehavior', '-v7.3');
fprintf('Analysis completed! Aggregated data saved to: %s\n', fullfile(parentPath, [mouseID '_AllDaysBehavior.mat']));

%% ====================== Helper functions ======================
function modeParams = getModeSpecificParams(mode, sampOdorLen)
% Get mode-specific markers/delays (centralized for easy maintenance)
switch mode
    case 1 % Single 10s delay
        modeParams.DelayLen = 10;
        modeParams.OutcomeDelayLabel = 1;
        modeParams.SampMarkers = {[13,5]; [14,6]};   % S1/S2
        modeParams.TestMarkers = {[12,4]; [15,7]};   % T1/T2
        modeParams.LickMarker = [0,1];
        modeParams.TestSampInterval = [sampOdorLen + modeParams.DelayLen - 0.05, sampOdorLen + modeParams.DelayLen + 0.05];

    case 2 % Dual-delay standard (10s/20s)
        modeParams.DelayLen = [10; 20];
        modeParams.OutcomeDelayLabel = [1,3];
        modeParams.SampMarkers = {[13,5]; [14,6]};   % S1/S2
        modeParams.TestMarkers = {[15,7]; [16,8]};   % T1/T2
        modeParams.LickMarker = [2,2];
        modeParams.TestSampInterval = [sampOdorLen + modeParams.DelayLen - 0.05, sampOdorLen + modeParams.DelayLen + 0.05];
        modeParams.LaserMarker = [65, 1];

    case 3 % Dual-delay pseudo-delay (10s/20s)
        modeParams.DelayLen = [10; 20];
        modeParams.OutcomeDelayLabel = [1,3];
        modeParams.SampMarkers = {[10,2]; [96,18]; [9,1]; [93,15]}; % S1-S4
        modeParams.TestMarkers = {[12,4]; [11,3]};   % T1/T2
        modeParams.LickMarker = [2,2];
        modeParams.TestSampInterval = [sampOdorLen + modeParams.DelayLen - 0.05, sampOdorLen + modeParams.DelayLen + 0.05];
        modeParams.LaserMarker = [65, 1];

    otherwise
        error('Invalid mode: %d (must be 1/2/3)', mode);
end
end

function validateConfig(cfg)
% Validate critical parameters to avoid runtime errors
if ~ismember(cfg.Mode, [1,2,3])
    error('Mode must be 1 (single delay), 2 (dual standard), or 3 (dual pseudo-delay)');
end
if ~ismember(cfg.IsLaserOnOff, [0,1])
    error('IsLaserOnOff must be 0 (no laser) or 1 (laser split)');
end
if cfg.Const.HitRateThres < 0 || cfg.Const.HitRateThres > 100
    warning('HitRateThres (%d) is outside 0-100 range (percent)', cfg.Const.HitRateThres);
end
end

function behaviorStruct = initBehaviorStruct(cfg, fileNum)
% Preallocate all-session behavior structure
behaviorStruct = struct();
delayLenList = cfg.ModeParams.DelayLen;

for delayIndex = 1:numel(delayLenList)
    delayVal = delayLenList(delayIndex);
    fieldName = sprintf('delay%d', delayVal);

    % Define base fields for each delay
    baseFields = struct();
    baseFields.TrialStructure = cell(1, fileNum);
    baseFields.NewTrialStructure = cell(1, fileNum);
    baseFields.WindowHitRate = cell(1, fileNum);
    baseFields.WindowMissRate = cell(1, fileNum);
    baseFields.WindowFalseRate = cell(1, fileNum);
    baseFields.WindowCRRate = cell(1, fileNum);
    baseFields.WindowPerf = cell(1, fileNum);
    baseFields.WindowPerf = cell(1, fileNum);
    baseFields.SessHitRate = [];
    baseFields.SessMissRate = [];
    baseFields.SessFalseRate = [];
    baseFields.SessCRRate = [];
    baseFields.SessPerf = [];
    baseFields.BinnedLickNum = cell(1, fileNum);
    baseFields.BinnedLickNum_Go = cell(1, fileNum);
    baseFields.BinnedLickNum_Hit = cell(1, fileNum);
    baseFields.BinnedLickNum_NoGo = cell(1, fileNum);
    baseFields.BinnedLickNum_False = cell(1, fileNum);

    if cfg.IsLaserOnOff == 0
        behaviorStruct.(fieldName) = baseFields;
    else
        % Add laser state subfields
        for laserIndex = 1:numel(cfg.LaserStates)
            behaviorStruct.(fieldName).(cfg.LaserStates{laserIndex}) = baseFields;
        end
    end
end
end

function events = extractCoreEvents(data, cfg)
% Extract samples/tests/outcomes/licks/laser from raw data
events = struct();
modeParams = cfg.ModeParams;
const = cfg.Const;

% 1. Extract sample stimuli (S1/S2/S1-S4)
[events.SampStartStamp, events.SampType] = extractStimuli(data, modeParams.SampMarkers);

% 2. Extract test stimuli (T1/T2)
[events.TestStartStamp, events.TestType] = extractStimuli(data, modeParams.TestMarkers, numel(modeParams.SampMarkers));

% 3. Extract laser events (if enabled)
if cfg.IsLaserOnOff == 1
    laserMask = ismember(data(:,3), modeParams.LaserMarker(1)) & ismember(data(:,4), modeParams.LaserMarker(2));
    events.LaserStartStamp = data(laserMask, 1);
end

% 4. Extract behavioral outcomes (Hit/Miss/FA/CR)
outcomeMask = ismember(data(:,3), const.OutcomeMarkers) & ismember(data(:,4), modeParams.OutcomeDelayLabel);
outcomeIdx = find(outcomeMask);

if ~isempty(outcomeIdx)
    events.OutcomeStamp = data(outcomeIdx, 1);
    events.OutcomeType = data(outcomeIdx, 3);
    events.OutcomeDelay = data(outcomeIdx, 4);

    % Map delay labels to actual durations
    for delayIndex = 1:numel(modeParams.DelayLen)
        events.OutcomeDelay(events.OutcomeDelay == modeParams.OutcomeDelayLabel(delayIndex)) = modeParams.DelayLen(delayIndex);
    end

    % Standardize outcome types (1=Hit, 2=Miss, 3=FA, 4=CR)
    events.OutcomeType = cell2mat(values(const.OutcomeMarkerToCode, num2cell(events.OutcomeType)));
    events.Outcome = [events.OutcomeType, events.OutcomeDelay];
else
    events.Outcome = [];
end

% 5. Extract & filter licking timestamps
lickMask = data(:,3) == modeParams.LickMarker(1) & data(:,4) == modeParams.LickMarker(2);
events.LickTime = data(lickMask, 1);

if ~isempty(events.LickTime)
    diffLick = diff(events.LickTime);
    validLickIdx = find(diffLick > const.LickThres) + 1;
    events.LickTime = events.LickTime(vertcat(1,validLickIdx));
end
end

function [startStamp, stimType] = extractStimuli(data, markers, offset)

startStamp = [];
stimType = [];
if nargin < 3, offset = 0; end

for stimIndex = 1:size(markers, 1)
    m1 = markers{stimIndex,1}(1);
    m2 = markers{stimIndex,1}(2);
    stimIdx = find(data(:,3) == m1 & data(:,4) == m2);

    if ~isempty(stimIdx)
        startStamp = [startStamp; data(stimIdx, 1)];
        stimType = [stimType; repmat(stimIndex + offset, numel(stimIdx), 1)];
    end
end

% Sort by timestamp
if ~isempty(startStamp)
    [startStamp, sortIdx] = sort(startStamp);
    stimType = stimType(sortIdx);
end
end

function events = standardizeTimestamps(events)
% Convert timestamps to seconds & align to earliest event (origin = 0)
allEventStamps = [events.SampStartStamp; events.TestStartStamp; events.OutcomeStamp];
if ~isempty(events.LickTime)
    allEventStamps = [allEventStamps; events.LickTime];
end

originTime = min(allEventStamps);
events.SampStartStamp = (events.SampStartStamp - originTime) / 1000;
events.TestStartStamp = (events.TestStartStamp - originTime) / 1000;
events.OutcomeStamp = (events.OutcomeStamp - originTime) / 1000;

if ~isempty(events.LickTime)
    events.LickTime = (events.LickTime - originTime) / 1000;
end
if isfield(events, 'LaserStartStamp') && ~isempty(events.LaserStartStamp)
    events.LaserStartStamp = (events.LaserStartStamp - originTime) / 1000;
end
end

function alignedTrials = alignTrialEvents(events, cfg)

alignedTrials = struct();
modeParams = cfg.ModeParams;
const = cfg.Const;

% Preallocate arrays
newSamp = zeros(0, 1);
newSampStartStamp = zeros(0, 1);
newTest = zeros(0, 1);
newTestStartStamp = zeros(0, 1);

% Step 1: Match samples to tests
if cfg.Mode == 1 % Single delay
    for sampIndex = 1:numel(events.SampStartStamp)
        sampTime = events.SampStartStamp(sampIndex);
        % Find test in valid interval
        testMask = events.TestStartStamp > sampTime + modeParams.TestSampInterval(1) ...
            & events.TestStartStamp < sampTime + modeParams.TestSampInterval(2);

        if any(testMask) && ~ismember(sampTime, newSampStartStamp)
            testIdx = find(testMask, 1, 'first');
            newSamp = [newSamp; events.SampType(sampIndex)];
            newSampStartStamp = [newSampStartStamp; sampTime];
            newTest = [newTest; events.TestType(testIdx)];
            newTestStartStamp = [newTestStartStamp; events.TestStartStamp(testIdx)];
        end
    end
else % Dual delay (Mode 2/3)
    for sampIndex = 1:numel(events.SampStartStamp)
        sampTime = events.SampStartStamp(sampIndex);
        matched = false;

        for delayIndex = 1:numel(modeParams.DelayLen)
            minInt = modeParams.TestSampInterval(delayIndex, 1);
            maxInt = modeParams.TestSampInterval(delayIndex, 2);

            testMask = events.TestStartStamp > sampTime + minInt ...
                & events.TestStartStamp < sampTime + maxInt;

            if any(testMask) && ~ismember(sampTime, newSampStartStamp)
                testIdx = find(testMask, 1, 'first');
                newSamp = [newSamp; events.SampType(sampIndex)];
                newSampStartStamp = [newSampStartStamp; sampTime];
                newTest = [newTest; events.TestType(testIdx)];
                newTestStartStamp = [newTestStartStamp; events.TestStartStamp(testIdx)];
                matched = true;
                break;
            end
        end
    end
end

% Step 2: Match tests to outcomes
newOutcome = zeros(0, 2);
invalidTrialIdx = [];

for testIndex = 1:length(newTestStartStamp)
    testTime = newTestStartStamp(testIndex);
    outcomeMask = events.OutcomeStamp > testTime + const.TestRespInterval - 0.5 ...
        & events.OutcomeStamp < testTime + const.TestRespInterval + const.RespWindowLen + 0.5;

    if any(outcomeMask)
        outcomeIdx = find(outcomeMask, 1, 'first');
        newOutcome = [newOutcome; events.Outcome(outcomeIdx, :)];
    else
        invalidTrialIdx = [invalidTrialIdx; testIndex];
    end
end

% Step 3: Remove invalid trials (ensure sample/test/outcome count matches)
newSamp(invalidTrialIdx) = [];
newSampStartStamp(invalidTrialIdx) = [];
newTest(invalidTrialIdx) = [];
newTestStartStamp(invalidTrialIdx) = [];

% Step 4: Build trial structure
if ~isempty(newSamp)
    eachTrialDelay = newTestStartStamp - newSampStartStamp - const.SampOdorLen;
    alignedTrials.TrialStructure = [newOutcome(:,2), newSampStartStamp, newSamp, ...
        eachTrialDelay, newTestStartStamp, newTest, newOutcome(:,1)];

    % Split by laser state (if enabled)
    if cfg.IsLaserOnOff == 1 && ~isempty(events.LaserStartStamp)
        alignedTrials = splitTrialsByLaser(alignedTrials, events.LaserStartStamp, const.SampOdorLen);
    end
else
    alignedTrials.TrialStructure = [];
end
end

function trials = splitTrialsByLaser(trials, laserStamps, sampOdorLen)
% Split trial structure by laser on/off state
trials.TrialStructure_LaserOn = [];
trials.TrialStructure_LaserOff = [];

for trialIndex = 1:size(trials.TrialStructure, 1)
    sampTime = trials.TrialStructure(trialIndex, 2);
    laserMask = laserStamps - sampTime > sampOdorLen + 0.5 - 0.5 ...
        & laserStamps - sampTime < sampOdorLen + 0.5 + 0.5;

    if any(laserMask)
        trials.TrialStructure_LaserOn = [trials.TrialStructure_LaserOn; trials.TrialStructure(trialIndex, :)];
    else
        trials.TrialStructure_LaserOff = [trials.TrialStructure_LaserOff; trials.TrialStructure(trialIndex, :)];
    end
end
end

function behavior = processTrialBehavior(alignedTrials, lickTime, cfg)
% Calculate performance metrics & process licking data
behavior = struct();
modeParams = cfg.ModeParams;
const = cfg.Const;

% Initialize behavior structure for each delay/laser state
for delayIndex = 1:numel(modeParams.DelayLen)
    delayVal = modeParams.DelayLen(delayIndex);
    fieldName = sprintf('delay%d', delayVal);
    behavior.(fieldName) = initPerDelayBehaviorStruct(cfg);
end

% Process laser-off mode (or no laser)
if cfg.IsLaserOnOff == 0
    for delayIndex = 1:numel(modeParams.DelayLen)
        delayVal = modeParams.DelayLen(delayIndex);
        fieldName = sprintf('delay%d', delayVal);

        % Filter trials by delay
        trialMask = alignedTrials.TrialStructure(:,1) == delayVal;
        trialStruct = alignedTrials.TrialStructure(trialMask, :);

        if ~isempty(trialStruct)
            behavior.(fieldName).TrialStructure = trialStruct;
            % Calculate performance (remove unmotivated trials)
            behavior.(fieldName) = CalculatePerfAfterRemovingUnmotivatedTrials(...
                trialStruct, cfg.MaxTrialsNum/numel(modeParams.DelayLen), ...
                cfg.MaxWindowNum, const.HitRateThres);

            % Process licking data
            [behavior.(fieldName).EachTrialLickTs, behavior.(fieldName).BinnedLickNum, ...
                behavior.(fieldName).BinnedLickNum_Go, behavior.(fieldName).BinnedLickNum_Hit, ...
                behavior.(fieldName).BinnedLickNum_NoGo, behavior.(fieldName).BinnedLickNum_False] = ...
                LickInEachSession(lickTime, behavior.(fieldName).NewTrialStructure, ...
                const.BaseLen, const.SampOdorLen, delayVal, const.TestOdorLen, ...
                const.TestRespInterval, const.RespWindowLen, const.AfterTrial);
        end
    end
else
    % Process laser-on/off states
    laserStates = cfg.LaserStates;
    for delayIndex = 1:numel(modeParams.DelayLen)
        delayVal = modeParams.DelayLen(delayIndex);
        fieldName = sprintf('delay%d', delayVal);

        for laserIndex = 1:numel(laserStates)
            laserState = laserStates{laserIndex};
            trialStruct = alignedTrials.(['TrialStructure_' laserState]);

            % Filter trials by delay
            trialMask = trialStruct(:,1) == delayVal;
            trialStruct = trialStruct(trialMask, :);

            if ~isempty(trialStruct)
                behavior.(fieldName).(laserState).TrialStructure = trialStruct;
                % Calculate performance
                behavior.(fieldName).(laserState) = CalculatePerfAfterRemovingUnmotivatedTrials(...
                    trialStruct, cfg.MaxTrialsNum/numel(modeParams.DelayLen), ...
                    cfg.MaxWindowNum, const.HitRateThres);

                % Process licking data
                [behavior.(fieldName).(laserState).EachTrialLickTs, ...
                    behavior.(fieldName).(laserState).BinnedLickNum, ...
                    behavior.(fieldName).(laserState).BinnedLickNum_Go, ...
                    behavior.(fieldName).(laserState).BinnedLickNum_Hit, ...
                    behavior.(fieldName).(laserState).BinnedLickNum_NoGo, ...
                    behavior.(fieldName).(laserState).BinnedLickNum_False] = ...
                    LickInEachSession(lickTime, behavior.(fieldName).(laserState).NewTrialStructure, ...
                    const.BaseLen, const.SampOdorLen, delayVal, const.TestOdorLen, ...
                    const.TestRespInterval, const.RespWindowLen, const.AfterTrial);
            end
        end
    end
end
end

function perDelayStruct = initPerDelayBehaviorStruct(cfg)
% Initialize per-delay behavior structure
perDelayStruct = struct(...
    'TrialStructure', [], 'NewTrialStructure', [], ...
    'WindowHitRate', [], 'WindowMissRate', [], 'WindowFalseRate', [], 'WindowCRRate', [], 'WindowPerf', [], ...
    'SessHitRate', [], 'SessMissRate', [], 'SessFalseRate', [], 'SessCRRate', [], 'SessPerf', [], ...
    'EachTrialLickTs', [], 'BinnedLickNum', [], 'BinnedLickNum_Go', [], ...
    'BinnedLickNum_Hit', [], 'BinnedLickNum_NoGo', [], 'BinnedLickNum_False', []);

% Add laser state subfields if needed
if cfg.IsLaserOnOff == 1
    for laserIndex = 1:numel(cfg.LaserStates)
        perDelayStruct.(cfg.LaserStates{laserIndex}) = perDelayStruct;
    end
end
end

function allSessionStruct = updateAllSessionStruct(allSessionStruct, behavior, cfg, fileIndex)
% Update aggregated all-session structure with current file's data
modeParams = cfg.ModeParams;

for delayIndex = 1:numel(modeParams.DelayLen)
    delayVal = modeParams.DelayLen(delayIndex);
    fieldName = sprintf('delay%d', delayVal);

    if cfg.IsLaserOnOff == 0
        % Update non-laser fields
        allSessionStruct.(fieldName).TrialStructure{fileIndex} = behavior.(fieldName).TrialStructure;
        allSessionStruct.(fieldName).NewTrialStructure{fileIndex} = behavior.(fieldName).NewTrialStructure;
        allSessionStruct.(fieldName).WindowHitRate{fileIndex} = behavior.(fieldName).WindowHitRate;
        allSessionStruct.(fieldName).WindowMissRate{fileIndex} = behavior.(fieldName).WindowMissRate;
        allSessionStruct.(fieldName).WindowFalseRate{fileIndex} = behavior.(fieldName).WindowFalseRate;
        allSessionStruct.(fieldName).WindowCRRate{fileIndex} = behavior.(fieldName).WindowCRRate;
        allSessionStruct.(fieldName).WindowPerf{fileIndex} = behavior.(fieldName).WindowPerf;

        % Append session-level metrics
        allSessionStruct.(fieldName).SessHitRate = [allSessionStruct.(fieldName).SessHitRate, behavior.(fieldName).SessHitRate];
        allSessionStruct.(fieldName).SessMissRate = [allSessionStruct.(fieldName).SessMissRate, behavior.(fieldName).SessMissRate];
        allSessionStruct.(fieldName).SessFalseRate = [allSessionStruct.(fieldName).SessFalseRate, behavior.(fieldName).SessFalseRate];
        allSessionStruct.(fieldName).SessCRRate = [allSessionStruct.(fieldName).SessCRRate, behavior.(fieldName).SessCRRate];
        allSessionStruct.(fieldName).SessPerf = [allSessionStruct.(fieldName).SessPerf, behavior.(fieldName).SessPerf];

        % Update licking data
        allSessionStruct.(fieldName).BinnedLickNum{fileIndex} = behavior.(fieldName).BinnedLickNum;
        allSessionStruct.(fieldName).BinnedLickNum_Go{fileIndex} = behavior.(fieldName).BinnedLickNum_Go;
        allSessionStruct.(fieldName).BinnedLickNum_Hit{fileIndex} = behavior.(fieldName).BinnedLickNum_Hit;
        allSessionStruct.(fieldName).BinnedLickNum_NoGo{fileIndex} = behavior.(fieldName).BinnedLickNum_NoGo;
        allSessionStruct.(fieldName).BinnedLickNum_False{fileIndex} = behavior.(fieldName).BinnedLickNum_False;

    else
        % Update laser state fields
        for laserIndex = 1:numel(cfg.LaserStates)
            laserState = cfg.LaserStates{laserIndex};
            allSessionStruct.(fieldName).(laserState).TrialStructure{fileIndex} = behavior.(fieldName).(laserState).TrialStructure;
            allSessionStruct.(fieldName).(laserState).NewTrialStructure{fileIndex} = behavior.(fieldName).(laserState).NewTrialStructure;
            allSessionStruct.(fieldName).(laserState).WindowHitRate{fileIndex} = behavior.(fieldName).(laserState).WindowHitRate;
            allSessionStruct.(fieldName).(laserState).WindowMissRate{fileIndex} = behavior.(fieldName).(laserState).WindowMissRate;
            allSessionStruct.(fieldName).(laserState).WindowFalseRate{fileIndex} = behavior.(fieldName).(laserState).WindowFalseRate;
            allSessionStruct.(fieldName).(laserState).WindowCRRate{fileIndex} = behavior.(fieldName).(laserState).WindowCRRate;
            allSessionStruct.(fieldName).(laserState).WindowPerf{fileIndex} = behavior.(fieldName).(laserState).WindowPerf;

            allSessionStruct.(fieldName).(laserState).SessHitRate = [allSessionStruct.(fieldName).(laserState).SessHitRate, behavior.(fieldName).(laserState).SessHitRate];
            allSessionStruct.(fieldName).(laserState).SessMissRate = [allSessionStruct.(fieldName).(laserState).SessMissRate, behavior.(fieldName).(laserState).SessMissRate];
            allSessionStruct.(fieldName).(laserState).SessFalseRate = [allSessionStruct.(fieldName).(laserState).SessFalseRate, behavior.(fieldName).(laserState).SessFalseRate];
            allSessionStruct.(fieldName).(laserState).SessCRRate = [allSessionStruct.(fieldName).(laserState).SessCRRate, behavior.(fieldName).(laserState).SessCRRate];
            allSessionStruct.(fieldName).(laserState).SessPerf = [allSessionStruct.(fieldName).(laserState).SessPerf, behavior.(fieldName).(laserState).SessPerf];

            allSessionStruct.(fieldName).(laserState).BinnedLickNum{fileIndex} = behavior.(fieldName).(laserState).BinnedLickNum;
            allSessionStruct.(fieldName).(laserState).BinnedLickNum_Go{fileIndex} = behavior.(fieldName).(laserState).BinnedLickNum_Go;
            allSessionStruct.(fieldName).(laserState).BinnedLickNum_Hit{fileIndex} = behavior.(fieldName).(laserState).BinnedLickNum_Hit;
            allSessionStruct.(fieldName).(laserState).BinnedLickNum_NoGo{fileIndex} = behavior.(fieldName).(laserState).BinnedLickNum_NoGo;
            allSessionStruct.(fieldName).(laserState).BinnedLickNum_False{fileIndex} = behavior.(fieldName).(laserState).BinnedLickNum_False;
        end
    end
end
end

function savePerFileData(behavior, savePath, mouseID, fileName)
% Save per-file behavior data with robust day ID extraction
dayID = regexp(fileName, '(?<=day)\d*', 'match', 'once');

saveFile = fullfile(savePath, sprintf('%s_day%s.mat', mouseID, dayID));
save(saveFile, 'behavior', '-v7.3');
end