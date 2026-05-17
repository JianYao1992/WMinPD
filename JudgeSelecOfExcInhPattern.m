function [SelecDirection, NeuType] = JudgeSelecOfExcInhPattern(DelaySelectivitySig, IsSampleDelaySigModulation, DelayFR, DelayDuration)
% Classify neuron type by delay-period selectivity & FR modulation
% INPUTS:
%   DelaySelectivitySig     - Delay-period selectivity pattern (matrix)
%   IsSampleDelaySigModulation - Modulation results: [all trials; S1 trials; S2 trials] (3×(OdorLen+DelayLen+1))
%   DelayFR                 - Delay-period mean FR: [all trials; S1 trials; S2 trials] (3×DelayDuration)
%   DelayDuration           - Delay period duration (seconds)
% OUTPUTS:
%   SelecDirection          - Odor preference: 1(S1-preferred)/2(S2-preferred)/0(Nonmemory)
%   NeuType                 - Neuron type string: "-[Preference]-[Modulation]"

%% 1. Core parameters
SigSelecBin = find(DelaySelectivitySig ~= 0); % Significant selectivity bins
DelayFRdiff = DelayFR(2,:) - DelayFR(3,:);    % S1 - S2 FR difference (delay period)
modThreshold = floor(DelayDuration / 3);      % Modulation bin count threshold

%% 2. Classify neuron based on significant selectivity bins
if ~isempty(SigSelecBin)
    % Get bin with maximum absolute FR difference (core for preference judgment)
    [~, maxDiffIdx] = max(abs(DelayFRdiff(SigSelecBin)));
    peakBinID = SigSelecBin(maxDiffIdx); % Bin ID with peak FR difference
    peakFRdiff = DelayFRdiff(peakBinID); % Peak S1-S2 FR difference
    
    % --------------------------
    % Case 1: S1-preferred neuron (peakFRdiff > 0)
    % --------------------------
    if peakFRdiff > 0
        SelecDirection = 1;
        % Extract S1-specific modulation parameters
        s1ModParams = getModulationParams(IsSampleDelaySigModulation(2,:), DelayFR(2,:), DelayDuration, modThreshold);
        % Determine neuron type (S1-preferred)
        NeuType = getS1PreferredType(s1ModParams, IsSampleDelaySigModulation, peakBinID);
    
    % --------------------------
    % Case 2: S2-preferred neuron (peakFRdiff < 0)
    % --------------------------
    elseif peakFRdiff < 0
        SelecDirection = 2;
        % Extract S2-specific modulation parameters
        s2ModParams = getModulationParams(IsSampleDelaySigModulation(3,:), DelayFR(3,:), DelayDuration, modThreshold);
        % Determine neuron type (S2-preferred)
        NeuType = getS2PreferredType(s2ModParams, IsSampleDelaySigModulation, peakBinID);
    end

% --------------------------
% Case 3: Nonmemory neuron (no significant selectivity bins)
% --------------------------
else
    SelecDirection = 0;
    % Extract all-trial modulation parameters
    nonMemModParams = getModulationParams(IsSampleDelaySigModulation(1,:), DelayFR(1,:), DelayDuration, modThreshold);
    % Determine nonmemory neuron type
    NeuType = getNonMemoryType(nonMemModParams);
end

end

function modParams = getModulationParams(modVector, frVector, DelayDuration, modThreshold)
% Output: struct with excitation/inhibition bin counts, max/min bin IDs, overall modulation direction
modParams.excBinNum = numel(find(modVector(2:1+DelayDuration) == 1));  % Excitation bin count
modParams.inhBinNum = numel(find(modVector(2:1+DelayDuration) == -1)); % Inhibition bin count
[~, modParams.maxFRbin] = max(frVector);  % Bin with maximum FR
[~, modParams.minFRbin] = min(frVector);  % Bin with minimum FR
modParams.overallDir = modVector(end);     % Overall modulation direction (from ModulationAndRampingAnalysis)
modParams.threshold = modThreshold;        % Modulation bin count threshold
end

function neuType = getS1PreferredType(s1Params, IsSampleDelaySigModulation, peakBinID)
% Classify S1-preferred neuron type (Excitation/Inhibition/S2-Inhibition)
neuType = '-S1Preferred-UnModulated'; % Default type

% Condition 1: S1 Excitation (single sig bin + peak bin excitation OR dominant excitation)
cond1 = IsSampleDelaySigModulation(2, peakBinID+1) == 1 ...
    || (IsSampleDelaySigModulation(2, peakBinID+1) == 0 ...
    && ((IsSampleDelaySigModulation(2, s1Params.maxFRbin+1) == 1 ...
    && s1Params.excBinNum > s1Params.inhBinNum ...
    && s1Params.inhBinNum <= s1Params.threshold) || (s1Params.overallDir == 1)));

% Condition 2: S1 Inhibition (single sig bin + peak bin inhibition OR dominant inhibition)
cond2 = IsSampleDelaySigModulation(2, peakBinID+1) == -1 ...
    || (IsSampleDelaySigModulation(2, peakBinID+1) == 0 ...
    && ((IsSampleDelaySigModulation(2, s1Params.minFRbin+1) == -1 ...
    && s1Params.excBinNum < s1Params.inhBinNum ...
    && s1Params.excBinNum <= s1Params.threshold) || (s1Params.overallDir == -1)));

% Condition 3: Overall S2 Inhibition (from ModulationAndRampingAnalysis)
cond3 = (IsSampleDelaySigModulation(3, peakBinID+1) == -1 || IsSampleDelaySigModulation(3, end) == -1);

% Assign neuron type
if cond1
    neuType = '-S1Preferred-S1Excitation';
elseif cond2
    neuType = '-S1Preferred-S1Inhibition';
elseif cond3
    neuType = '-S1Preferred-S2Inhibition';
end
end

function neuType = getS2PreferredType(s2Params, IsSampleDelaySigModulation, peakBinID)
% Classify S2-preferred neuron type (Excitation/Inhibition/S1-Inhibition)
neuType = '-S2Preferred-UnModulated'; % Default type

% Condition 1: S2 Excitation (single sig bin + peak bin excitation OR dominant excitation)
cond1 = IsSampleDelaySigModulation(3, peakBinID+1) == 1 ...
    || (IsSampleDelaySigModulation(3, peakBinID+1) == 0 ...
    && ((IsSampleDelaySigModulation(3, s2Params.maxFRbin+1) == 1 ...
    && s2Params.excBinNum > s2Params.inhBinNum ...
    && s2Params.inhBinNum <= s2Params.threshold) || (s2Params.overallDir == 1)));

% Condition 2: S2 Inhibition (single sig bin + peak bin inhibition OR dominant inhibition)
cond2 = IsSampleDelaySigModulation(3, peakBinID+1) == -1 ...
    || (IsSampleDelaySigModulation(3, peakBinID+1) == 0 ...
    && ((IsSampleDelaySigModulation(3, s2Params.minFRbin+1) == -1 ...
    && s2Params.excBinNum < s2Params.inhBinNum ...
    && s2Params.excBinNum <= s2Params.threshold) || (s2Params.overallDir == -1)));

% Condition 3: Overall S1 Inhibition (from ModulationAndRampingAnalysis)
cond3 = (IsSampleDelaySigModulation(2, peakBinID+1) == -1 || IsSampleDelaySigModulation(2, end) == -1);

% Assign neuron type
if cond1
    neuType = '-S2Preferred-S2Excitation';
elseif cond2
    neuType = '-S2Preferred-S2Inhibition';
elseif cond3
    neuType = '-S2Preferred-S1Inhibition';
end
end

function neuType = getNonMemoryType(nonMemParams)
% Classify Nonmemory neuron type (Excitation/Inhibition)
neuType = '-Nonmemory-UnModulated'; % Default type

% Assign neuron type
if nonMemParams.overallDir == 1
    neuType = '-Nonmemory-Excitation';
elseif nonMemParams.overallDir == -1
    neuType = '-Nonmemory-Inhibition';
end
end