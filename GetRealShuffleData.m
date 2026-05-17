function [RealData, ShuffleData] = GetRealShuffleData(UnitBinnedFR, UnitTrialID, NumTrialForEachCondition)
% Calculate real and shuffled (1000 iterations) selectivity for neurons
% INPUT:
%   UnitBinnedFR       - Cell array of binned firing rates for each trial
%   UnitTrialID        - Cell array of trial IDs for different conditions
%   NumTrialForEachCondition - Trial count per condition (can be empty)
% OUTPUT:
%   RealData           - Real selectivity values (x-y)/(x+y), NaN/Inf → 0
%   ShuffleData        - 1000 iterations of shuffled selectivity averages

%% Compute real selectivity
[S1TrialFR, ~, ~, S2TrialFR] = ExtractSpecTrialNumForEachNeuron(...
    UnitBinnedFR, UnitTrialID, NumTrialForEachCondition, 0, 0);

% mean firing rate across trials for each condition
mean1FR = cellfun(@(x) mean(x, 1), S1TrialFR, 'UniformOutput', false);
mean2FR = cellfun(@(x) mean(x, 1), S2TrialFR, 'UniformOutput', false);

% calculate selectivity:
RealData = cellfun(@(x, y) (x - y) ./ (x + y), mean1FR, mean2FR, 'UniformOutput', false);
RealData = vertcat(RealData{:});

% remove invalid values (NaN/Inf)
RealData(isnan(RealData) | isinf(RealData)) = 0;

%% Compute 1000 shuffled selectivities
nShuffle = 1000;
nBins = size(RealData, 2);
ShuffleData = zeros(nShuffle, nBins);

for iShuf = 1:nShuffle
    % extract shuffled trial data
    [S1TrialFR_shuf, ~, ~, S2TrialFR_shuf] = ExtractSpecTrialNumForEachNeuron(...
        UnitBinnedFR, UnitTrialID, NumTrialForEachCondition, 1, 0);
    
    % mean firing rate for shuffled trials
    mean1_shuf = cellfun(@(x) mean(x, 1), S1TrialFR_shuf, 'UniformOutput', false);
    mean2_shuf = cellfun(@(x) mean(x, 1), S2TrialFR_shuf, 'UniformOutput', false);
    
    % shuffled selectivity
    tempShuf = cellfun(@(x, y) (x - y) ./ (x + y), mean1_shuf, mean2_shuf, 'UniformOutput', false);
    tempShuf = vertcat(tempShuf{:});
    tempShuf(isnan(tempShuf) | isinf(tempShuf)) = 0;
    ShuffleData(iShuf, :) = mean(tempShuf, 1);
    
    % Progress display
    fprintf('Finished shuffled iteration %d/%d\n', iShuf, nShuffle);
end

end