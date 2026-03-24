function [LickinEachTrial, LickNum, LickNum_Go, LickNum_Hit, LickNum_NoGo, LickNum_False] = LickInEachSession( ...
    LickTs, TrialStructure, BaselineDuration, SampleDuration, DelayDuration, TestDuration, ...
    TestResponseIntervalDuration, ResponseWindowDuration, AfterTrialDuration)
    Bin = 0.1;
    numTrials = size(TrialStructure, 1);
    TestOdorStart = TrialStructure(:, 5);
    trialTotalDuration = BaselineDuration + SampleDuration + DelayDuration + TestDuration + ...
        TestResponseIntervalDuration + ResponseWindowDuration + AfterTrialDuration;
    trialTimeRange = [TestOdorStart - BaselineDuration - SampleDuration - DelayDuration, ...
        TestOdorStart + trialTotalDuration - BaselineDuration - SampleDuration - DelayDuration];
    
    % preallocate memory
    numBinsPerTrial = ceil(trialTotalDuration / Bin);
    LickNum = zeros(numTrials, numBinsPerTrial);
    LickinEachTrial = cell(numTrials, 1);
    
    % full vectorization: leveraging the properties of sorted LickTs to quickly locate licks for each trial using "find"
    if isempty(LickTs)
        return;  % return directly when there is no licking data
    end
    
    % generate the bin edges for all trials (a numTrials × (numBinsPerTrial+1) array)
    binEdges = trialTimeRange(:, 1) + (0:numBinsPerTrial)' * Bin;
    % ensure the last bin contains tEnd
    binEdges(:, end) = max([binEdges(:, end), trialTimeRange(:, 2)],[],2);
    
    % vectorize the calculation of lick counts for each trial (utilizing the vectorization feature of histcounts)
    for i = 1:numTrials
        % filter the licks for the current trial
        idxStart = find(LickTs > trialTimeRange(i, 1), 1, 'first');
        idxEnd = find(LickTs <= trialTimeRange(i, 2), 1, 'last');
        if isempty(idxStart) || isempty(idxEnd)
            LickNum(i, :) = 0;
            LickinEachTrial{i} = [];
            continue;
        end
        trialLickTs = LickTs(idxStart:idxEnd);
        LickinEachTrial{i} = trialLickTs - trialTimeRange(i, 1);
        LickNum(i, :) = histcounts(trialLickTs, binEdges(i, :));
    end
    
    % calculate the average value of different types of trials
    trialType = TrialStructure(:, 7);
    LickNum_Go = mean(LickNum(trialType == 1 | trialType == 2, :), 1);
    LickNum_Hit = mean(LickNum(trialType == 1, :), 1);
    LickNum_NoGo = mean(LickNum(trialType == 3 | trialType == 4, :), 1);
    LickNum_False = mean(LickNum(trialType == 3, :), 1);
end