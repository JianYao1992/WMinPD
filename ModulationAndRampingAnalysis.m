function [IsSampleDelaySigModulation, SecondModuPValue, SecondModulation, IsRampingNeu, BaselineDelaySecondMeanFR] = ModulationAndRampingAnalysis(FR, BaselinePeriod, BaselineDuration, OdorLen, DelayLen, TimeGain, SamplePeriod)
% Analyze neuron FR modulation (baseline vs sample/delay) & ramping pattern
% INPUTS:
%   FR                  - Firing rate matrix (nTrials×nBins) for target trials
%   BaselinePeriod      - Bin range of baseline period (vector: [start, end])
%   BaselineDuration    - Total baseline duration (seconds)
%   OdorLen/DelayLen    - Sample odor/delay period durations (seconds)
%   TimeGain            - Time gain (bins per second)
%   SamplePeriod        - Bin range of sample period (vector: [start, end])
% OUTPUTS:
%   IsSampleDelaySigModulation - Modulation result: [sample + delay modulation (±1/0), overall direction (±1/0)]
%   SecondModuPValue    - P-values for sample/delay modulation (1×(OdorLen+DelayLen))
%   IsRampingNeu        - Ramping pattern: 1(upward)/-1(downward)/0(no ramping)
%   BaselineDelaySecondMeanFR - Mean FR: [baseline FR, delay-period second-wise mean FR]

%% 1. Initialization
IsSampleDelaySigModulation = zeros(1, OdorLen + DelayLen + 1); % +1 for overall modulation direction
SecondModuPValue = zeros(1, OdorLen + DelayLen);
SecondModulation = zeros(1, OdorLen + DelayLen); 
IsRampingNeu = 0; % default: no ramping

%% 2. Modulation in sample period (baseline vs sample)
[Psample, ~, BaselineFR, SampleFR, ~] = RankSumSigTest(FR, FR, BaselinePeriod, SamplePeriod);
SecondModuPValue(1) = Psample;

% judge modulation significance & direction (1=excitory, -1=inhibitory, 0=no modulation)
if Psample < 0.05
    SecondModulation(1) = ceil(SampleFR - BaselineFR);
    if SampleFR > BaselineFR
        IsSampleDelaySigModulation(1) = 1;
    else
        IsSampleDelaySigModulation(1) = -1;
    end
end

%% 3. Modulation in delay period (baseline vs each second of delay)
TrialAverFR = mean(FR); % trial-averaged FR across all bins
SecondMeanFR = zeros(1, DelayLen); % second-wise mean FR for delay period

for iDelay = 1:DelayLen
    tarDelayBinStart = (BaselineDuration + OdorLen + iDelay - 1)*TimeGain + 2;
    tarDelayBinEnd = (BaselineDuration + OdorLen + iDelay)*TimeGain + 1;
    TarDelayPeriod = tarDelayBinStart:tarDelayBinEnd;
    
    % calculate second-wise mean FR for current delay second
    SecondMeanFR(iDelay) = mean(TrialAverFR(TarDelayPeriod));
    
    % ranksum test (baseline vs current delay second) + correction (p×DelayLen)
    [p, ~, BaselineFR, TarDelayFR, ~] = RankSumSigTest(FR, FR, BaselinePeriod, TarDelayPeriod);
    correctedP = p * round(DelayLen);
    SecondModuPValue(iDelay + 1) = correctedP;
    
    % judge modulation significance & direction in delay period
    if correctedP < 0.05
        SecondModulation(iDelay + 1) = ceil(TarDelayFR - BaselineFR);
        if TarDelayFR > BaselineFR
            IsSampleDelaySigModulation(iDelay + 1) = 1;
        else
            IsSampleDelaySigModulation(iDelay + 1) = -1;
        end
    end
end

%% 4. Overall modulation direction (excitory/inhibitory)
delayModulation = IsSampleDelaySigModulation(2:OdorLen+DelayLen); % extract delay-period modulation
sigModBinNum = nnz(delayModulation ~= 0); % number of significant delay bins
excBinID = find(delayModulation == 1);    % excitory bin IDs
inhBinID = find(delayModulation == -1);   % inhibitory bin IDs
modDirection = 0; % default: no dominant direction

% determine dominant modulation direction
if sigModBinNum >= 2
    if ~isempty(excBinID) && isempty(inhBinID)
        modDirection = 1;
    elseif isempty(excBinID) && ~isempty(inhBinID)
        modDirection = -1;
    elseif length(excBinID) > length(inhBinID)
        modDirection = 1;
    elseif length(excBinID) < length(inhBinID)
        modDirection = -1;
    elseif length(excBinID) == length(inhBinID) && ~isempty(excBinID)
        % compare earliest significant bin to determine direction
        if min(inhBinID) < min(excBinID)
            modDirection = -1;
        else
            modDirection = 1;
        end
    end
end
IsSampleDelaySigModulation(end) = modDirection; % append overall direction to output

%% 5. Ramping pattern analysis (upward/downward/no ramping)
if DelayLen >= 2 % Ramping requires at least 2 delay seconds (valid diff calculation)
    frDiff = diff(SecondMeanFR); % Difference between consecutive delay seconds
    if all(frDiff >= 0) % All differences ≥0 → upward ramping
        IsRampingNeu = 1;
    elseif all(frDiff <= 0) % All differences ≤0 → downward ramping
        IsRampingNeu = -1;
    end
end

%% 6. Aggregate baseline & delay mean FR
BaselineDelaySecondMeanFR = [BaselineFR, SecondMeanFR];

end