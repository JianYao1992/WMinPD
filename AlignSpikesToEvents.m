function [TrialMark, AllTrialSpkRg, AllTrialSpkFR, LaserSpkRg, LaserSpkFR, LickTs, LickRate] = AlignSpikesToEvents(SpkTs, OdorAtime, OdorBtime, LickTime, LaserTime, varargin)
% Align neuronal spikes/licking signals with experimental events
% Inputs:
%   SpkTs          - Neuronal spike timestamps
%   OdorAtime/OdorBtime - Odor A/Odor B trigger timestamps
%   LickTime       - Licking signal timestamps
%   LaserTime      - Laser timestamps (basic mode = single array; laser on/off mode = 1 × 2 cell array [task, rest])
%   LaserTrialNum  - (basic mode = numeric value; laser on/off mode = 1 × 2 numeric matrix [task, rest])
%   SampleLen/DelayLen/TestLen - Duration of sample/delay/test phase
%   RespWinLen     - Response window duration
%   iti            - Inter-trial interval duration
%   TimeGain       - Time gain factor for firing rate calculation
% Outputs:
%   TrialMark      - Trial marker (basic mode = numeric matrix; laser on/off mode = struct [laseron/laseroff])
%   AllTrialSpkRg  - Spike raster for all trials (same format as TrialMark)
%   AllTrialSpkFR  - Firing rate for all trials (same format as TrialMark)
%   LaserSpkRg     - Spike raster for laser trials (basic mode = cell array; laser on/off mode = resting-state spike raster)
%   LaserSpkFR     - Firing rate for laser trials (basic mode = cell array; laser on/off mode = resting-state firing rate)
%   LickTs/LickRate- Aligned licking timestamps/licking rate (same format as TrialMark)

%% ===================== Initialize parameters and determine mode =====================
% parse variable arguments & determine mode: laser_mode=1 (Basic mode) / 2 (Laser On/Off mode)
if ~isempty(varargin{1})
    laser_mode = 1;
    LaserTrialNum = varargin{1};
    SampleLen = varargin{2}; DelayLen = varargin{3}; TestLen = varargin{4};
    RespWinLen = varargin{5}; iti = varargin{6}; TimeGain = varargin{7};
else
    laser_mode = 2;
    LaserTime_task = LaserTime{1}; LaserTime_rest = LaserTime{2};
    SampleLen = varargin{2}; DelayLen = varargin{3}; TestLen = varargin{4};
    RespWinLen = varargin{5}; iti = varargin{6}; TimeGain = varargin{7};
end
% fixed parameters
BeforeFirstOdor = iti - 2;
AfterLaser = iti - 2;
LaserSpkRg = []; LaserSpkFR = [];

%% ===================== 1. Calculate neuronal firing rate =====================
if ~isempty(SpkTs)
    max_spk = ceil(max(SpkTs));
    FiringRate = zeros(1, TimeGain * max_spk);
    for itr = 1:numel(SpkTs)
        spk_idx = ceil(TimeGain * SpkTs(itr));
		FiringRate(1,spk_idx) = FiringRate(1,spk_idx) + 1;
	end
    FiringRate = TimeGain * FiringRate; % convert to firing rate
else
    FiringRate = [];
end

%% ===================== 2. Filter licking signals (denoising) =====================
NewLickTime = [];
if ~isempty(LickTime)
    NewLickTime = LickTime(1, :);
    for itr = 2:numel(LickTime)
        if (LickTime(itr) - LickTime(itr-1) > 0.031) || (LickTime(itr) - NewLickTime(end) > 0.1)
            NewLickTime = [NewLickTime; LickTime(itr)];
        end
    end
end

%% ===================== 3. Filter odor signals (denoise and retain valid trials) =====================
Odor = sortrows([OdorAtime; OdorBtime]);
if ~isempty(Odor)
    i = 1;
    while i < size(Odor, 1)
        % determine preceding valid trials
        pre_valid = find(Odor(1:i-1, 2) ~= 0);
        if i == 1 || isempty(pre_valid)
            % first trial/no preceding valid trials: judge if the interval is compliant
            if abs(Odor(i+1,1)-Odor(i,1) - (SampleLen+DelayLen)) < 0.5
                i = i + 2;
            else
                Odor(i,2) = 0; i = i + 1;
            end
        else  
            % preceding valid trials exist: dual interval judgment
            cond1 = Odor(i,1)-Odor(pre_valid(end),1) - (iti+TestLen+RespWinLen) > -0.5;
            cond2 = abs(Odor(i+1,1)-Odor(i,1) - (SampleLen+DelayLen)) < 0.5;
            if cond1 && cond2
                i = i + 2;
            else
                Odor(i,2) = 0; i = i + 1;
            end
        end
    end
    % filter the last trial under special conditions
    remain = find(Odor(1:end-1, 2) ~= 0);
    if ~isempty(remain) && length(remain)>=2
        if abs(Odor(remain(end),1)-Odor(remain(end-1),1) - (SampleLen+DelayLen)) < 0.3
            Odor(end,2) = 0;
        end
    end
    Odor(Odor(:,2)==0, :) = []; % remove invalid trials
end

%% ===================== 4. Calculate response window (CheckStart/CheckEnd) =====================
TestOdorStartTime = [];
if ~isempty(Odor)
    Odor = Odor';
    % extract timestamps of even columns (test odors)
    TestOdorStartTime = Odor(:, mod(1:size(Odor,2),2)==0);
end
CheckStart = TestOdorStartTime(1,:) + TestLen;  % start of response window
CheckEnd = CheckStart + RespWinLen;            % end of response window
num_trial = numel(CheckEnd);                   % number of valid trials

%% ===================== 5. Extend firing rate array (prevent index out of bounds) =====================
if ~isempty(FiringRate) && num_trial>0
    if laser_mode == 1
        fr_max_idx = round(CheckEnd(end)*TimeGain) + ceil(AfterLaser)*TimeGain;
    else
        fr_max_idx = round(LaserTime_rest(end)*TimeGain) + ceil(DelayLen+AfterLaser)*TimeGain;
    end
    temp = fr_max_idx - numel(FiringRate);
    if temp > 0
        FiringRate = [FiringRate, zeros(1, temp+1)];
    end
end

%% ===================== 6. Mode 1: basic mode-processing of all trials + resting-state laser trials =====================
if laser_mode == 1
    TrialMark = []; AllTrialSpkRg = []; AllTrialSpkFR = [];
    LickTs = []; LickRate = [];
    % filtering of laser trial timestamps
    LaserStart = [];
    if ~isempty(LaserTime) && length(LaserTime)<=LaserTrialNum
        LaserStart = LaserTime;
    end
    % iterate through all behavioral trials
    for iTrial = 1:num_trial
        % time window boundaries
        win_start = CheckEnd(iTrial) - (BeforeFirstOdor+SampleLen+DelayLen+TestLen+RespWinLen);
        win_end = CheckEnd(iTrial) + AfterLaser;
        % align spike raster and firing rate
        spk_rg = SpkTs(SpkTs>win_start & SpkTs<win_end) - win_start;
        AllTrialSpkRg = [AllTrialSpkRg, {spk_rg}];
        fr_idx = round(CheckEnd(iTrial)*TimeGain) + ceil([-(BeforeFirstOdor+SampleLen+DelayLen+TestLen+RespWinLen), AfterLaser])*TimeGain;
        AllTrialSpkFR = [AllTrialSpkFR, {FiringRate(fr_idx(1):fr_idx(2))}];
        % extract sample and test odors for the current trial
        SampOdor = Odor(2, abs(Odor(1,:)+SampleLen+DelayLen+TestLen-CheckStart(iTrial))<1);
        TestOdor = Odor(2, abs(Odor(1,:)+TestLen-CheckStart(iTrial))<1);
        % align licking signals and calculate licking rate
        lick_rg = NewLickTime(NewLickTime>win_start & NewLickTime<win_end) - win_start;
        LickTs = [LickTs, {lick_rg}];
        % calculate licking rate in bins
        t_vec = win_start:1/TimeGain:win_end-1/TimeGain;
        BinnedLickNum = arrayfun(@(t) sum(NewLickTime>t & NewLickTime<=t+1/TimeGain), t_vec);
        LickRate = [LickRate; BinnedLickNum];
        % trial labeling (1 = hit, 2 = miss, 3 = FA, 4 = CR)
        lick_resp = isempty(find(NewLickTime>CheckStart(iTrial) & NewLickTime<CheckEnd(iTrial)));
        if ismember([SampOdor,TestOdor], [[1,2],[2,1]], 'rows')
            TrialMark = [TrialMark; [SampOdor, TestOdor, lick_resp+1]];
        else
            TrialMark = [TrialMark; [SampOdor, TestOdor, lick_resp+3]];
        end
    end
    % alignment of firing signals for laser trials
    if ~isempty(LaserStart)
        for iTrial = 1:size(LaserStart,1)
            win_start = LaserStart(iTrial) - BeforeFirstOdor;
            win_end = LaserStart(iTrial) + DelayLen + AfterLaser;
            spk_rg = SpkTs(SpkTs>win_start & SpkTs<win_end) - win_start;
            LaserSpkRg = [LaserSpkRg, {spk_rg}];
            fr_idx = round(LaserStart(iTrial)*TimeGain) + ceil([-BeforeFirstOdor, DelayLen+AfterLaser])*TimeGain;
            LaserSpkFR = [LaserSpkFR, {FiringRate(fr_idx(1):fr_idx(2))}];
        end
    end

%% ===================== 7. Mode 2：split into task-condition and resting-state laser trials =====================
elseif laser_mode == 2
    % initialize structure (split into laser on / laser off)
    TrialMark = struct('laseron', [], 'laseroff', []);
    AllTrialSpkRg = struct('laseron', [], 'laseroff', []);
    AllTrialSpkFR = struct('laseron', [], 'laseroff', []);
    LickTs = struct('laseron', [], 'laseroff', []);
    LickRate = struct('laseron', [], 'laseroff', []);
    % iterate through all behavioral trials
    for iTrial = 1:num_trial
        % time window boundaries
        win_start = CheckEnd(iTrial) - (BeforeFirstOdor+SampleLen+DelayLen+TestLen+RespWinLen);
        win_end = CheckEnd(iTrial) + AfterLaser;
        % extract sample/test odors and timestamps for the current trial
        SampOdor = Odor(2, abs(Odor(1,:)+SampleLen+DelayLen+TestLen-CheckStart(iTrial))<1);
        SampOdorTs = Odor(1, abs(Odor(1,:)+SampleLen+DelayLen+TestLen-CheckStart(iTrial))<1);
        TestOdor = Odor(2, abs(Odor(1,:)+TestLen-CheckStart(iTrial))<1);
        TestOdorTs = Odor(1, abs(Odor(1,:)+TestLen-CheckStart(iTrial))<1);
        % determine if the current trial is a laser-on trial
        is_laseron = nnz(LaserTime_task>SampOdorTs & LaserTime_task<TestOdorTs) > 0;
        % align spike raster and firing rate
        spk_rg = SpkTs(SpkTs>win_start & SpkTs<win_end) - win_start;
        fr_idx = round(CheckEnd(iTrial)*TimeGain) + ceil([-(BeforeFirstOdor+SampleLen+DelayLen+TestLen+RespWinLen), AfterLaser])*TimeGain;
        fr_rg = FiringRate(fr_idx(1):fr_idx(2));
        % align licking signals and calculate licking rate
        lick_rg = NewLickTime(NewLickTime>win_start & NewLickTime<win_end) - win_start;
        t_vec = win_start:1/TimeGain:win_end-1/TimeGain;
        BinnedLickNum = arrayfun(@(t) sum(NewLickTime>t & NewLickTime<=t+1/TimeGain), t_vec);
        % trial marking
        lick_resp = isempty(find(NewLickTime>CheckStart(iTrial) & NewLickTime<CheckEnd(iTrial)));
        if ismember([SampOdor,TestOdor], [[1,2],[2,1]], 'rows')
            mark = [SampOdor, TestOdor, lick_resp+1];
        else
            mark = [SampOdor, TestOdor, lick_resp+3];
        end
        % assign data by laser on/off status
        if is_laseron
            AllTrialSpkRg.laseron = [AllTrialSpkRg.laseron, {spk_rg}];
            AllTrialSpkFR.laseron = [AllTrialSpkFR.laseron, {fr_rg}];
            LickTs.laseron = [LickTs.laseron, {lick_rg}];
            LickRate.laseron = [LickRate.laseron; BinnedLickNum];
            TrialMark.laseron = [TrialMark.laseron; mark];
        else
            AllTrialSpkRg.laseroff = [AllTrialSpkRg.laseroff, {spk_rg}];
            AllTrialSpkFR.laseroff = [AllTrialSpkFR.laseroff, {fr_rg}];
            LickTs.laseroff = [LickTs.laseroff, {lick_rg}];
            LickRate.laseroff = [LickRate.laseroff; BinnedLickNum];
            TrialMark.laseroff = [TrialMark.laseroff; mark];
        end
    end
    % alignment of firing signals in resting-state laser trials
    if ~isempty(LaserTime_rest)
        for iTrial = 1:size(LaserTime_rest,1)
            win_start = LaserTime_rest(iTrial) - BeforeFirstOdor;
            win_end = LaserTime_rest(iTrial) + DelayLen + AfterLaser;
            spk_rg = SpkTs(SpkTs>win_start & SpkTs<win_end) - win_start;
            LaserSpkRg = [LaserSpkRg, {spk_rg}];
            fr_idx = round(LaserTime_rest(iTrial)*TimeGain) + ceil([-BeforeFirstOdor, DelayLen+AfterLaser])*TimeGain;
            LaserSpkFR = [LaserSpkFR, {FiringRate(fr_idx(1):fr_idx(2))}];
        end
    end
end

end