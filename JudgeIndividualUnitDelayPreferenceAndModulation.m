function UnitPreferenceModulationId = JudgeIndividualUnitDelayPreferenceAndModulation(FR_S1, FR_S2, SelectivitySig, BaselineDuration, ComparedBaselineDuration, SampleDuration, DelayDuration, TimeGain)
% Determine neuron delay-period preference & FR modulation (vs baseline)
% INPUTS:
%   FR_S1/FR_S2             - Firing rate matrices for S1/S2 trials (nTrials×nBins)
%   SelectivitySig          - Selectivity pattern matrix
%   BaselineDuration        - Total baseline duration (seconds)
%   ComparedBaselineDuration- Visible baseline duration for comparison (seconds)
%   SampleDuration/DelayDuration - Task period durations (seconds)
% OUTPUT:
%   UnitPreferenceModulationId - Neuron preference & modulation type ID

%% 1. Time periods (bin indices) for analysis
% Baseline period bin range (for modulation comparison)
BaselinePeriod = (BaselineDuration - ComparedBaselineDuration)*TimeGain + 2 : BaselineDuration*TimeGain + 1;
% Sample period bin range
SamplePeriod = BaselineDuration*TimeGain + 2 : (BaselineDuration + SampleDuration)*TimeGain + 1;

%% 2. Modulation & ramping analysis (all trials + S1/S2 separate trials)
% all trials (S1 + S2 combined)
[IsSampDelaySigModulation_all, ~, ~, ~, BaseDelaySecondMeanFR_all] = ModulationAndRampingAnalysis(...
    vertcat(FR_S1, FR_S2), BaselinePeriod, BaselineDuration, SampleDuration, DelayDuration, TimeGain, SamplePeriod);
% S1 trials only
[IsSampDelaySigModulation_S1, ~, ~, ~, BaseDelaySecondMeanFR_S1] = ModulationAndRampingAnalysis(...
    FR_S1, BaselinePeriod, BaselineDuration, SampleDuration, DelayDuration, TimeGain, SamplePeriod);
% S2 trials only
[IsSampDelaySigModulation_S2, ~, ~, ~, BaseDelaySecondMeanFR_S2] = ModulationAndRampingAnalysis(...
    FR_S2, BaselinePeriod, BaselineDuration, SampleDuration, DelayDuration, TimeGain, SamplePeriod);

%% 3. Aggregate results for preference/modulation judgment
% combine modulation direction (all trials + S1 + S2)
IsSampDelaySigModulation = [IsSampDelaySigModulation_all; IsSampDelaySigModulation_S1; IsSampDelaySigModulation_S2];
% averaged delay-period firing rate
DelayFR = vertcat(BaseDelaySecondMeanFR_all(:, 2:end), BaseDelaySecondMeanFR_S1(:, 2:end), BaseDelaySecondMeanFR_S2(:, 2:end));

%% 4. Extract delay-period selectivity significance
DelaySelectivitySig = SelectivitySig(:, BaselineDuration + SampleDuration + 1 : BaselineDuration + SampleDuration + DelayDuration);

%% 5. Judge final preference & modulation type
[~, UnitPreferenceModulationId] = JudgeSelecOfExcInhPattern(DelaySelectivitySig, IsSampDelaySigModulation, DelayFR, DelayDuration);

end