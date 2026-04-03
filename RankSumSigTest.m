function [p, h, MeanValue1, MeanValue2, SelectivityIndex] = RankSumSigTest(s1TrialValue, s2TrialValue, EventPeriod, EventPeriod2)
% Perform ranksum test to compare values between two event periods
% INPUTS:
%   s1TrialValue/s2TrialValue - Matrices (nTrials×nBins) for two trial groups
%   EventPeriod/EventPeriod2  - Bin ranges of the two target event periods (vectors: [start, end])
% OUTPUTS:
%   p            - P-value from ranksum test (significance of difference)
%   h            - Hypothesis test result (1 = reject null hypothesis, 0 = fail to reject)
%   MeanValue1/MeanValue2 - Trial-averaged FR for EventPeriod/EventPeriod2
%   SelectivityIndex - Selectivity index: (MeanValue1 - MeanValue2)/(MeanValue1 + MeanValue2)

% calculate trial-wise mean FR for each event period
trialMeanFR1 = mean(s1TrialValue(:, EventPeriod), 2); % trial-averaged FR for EventPeriod
trialMeanFR2 = mean(s2TrialValue(:, EventPeriod2), 2); % trial-averaged FR for EventPeriod2

% ranksum test (compare FR distributions between the two periods)
[p, h] = ranksum(trialMeanFR1, trialMeanFR2);

% overall mean FR (average across all trials)
MeanValue1 = mean(trialMeanFR1);
MeanValue2 = mean(trialMeanFR2);

% selectivity index
SelectivityIndex = (MeanValue1 - MeanValue2) ./ (MeanValue1 + MeanValue2);

end