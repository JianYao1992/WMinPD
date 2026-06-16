function varargout = ClusterBasedPermutationTest(mode, data1,data2,BinNum,ShuffleTimes,OneOrTwoSidedTest)
%   Two operational modes are supported:
%   1. 'Between recording and shuffle'
%   2. 'Between recordings'
%
%   Syntax:
%   - For 'Between recording and shuffle' mode:
%     [ClusBasedPermuTestSigTime,ClusBasedPermuTestSigLessThanChanceTime,Persistence] = ...
%          ClusterBasedPermutationTest('Between recording and shuffle', RecordingDecodingResults, ShuffleTCTDecodingNullDistribution, TestBinNum, ShuffleTimes, SingleOrTwoSidesTest)
%
%   - For 'Between recordings' mode:
%     [ClusBasedPermuTestSigTime, ClusBasedPermuTestSigLessThanChanceTime] = ClusterBasedPermutationTest('Between recordings', data1, data2)
%
%   Inputs:
%   - mode: 'Between recording and shuffle' or 'Between recordings' to select analysis type
%   - varargin: Variable input arguments matching the selected mode's requirements
%
%   varargout:
%   - independent variables

addpath(genpath('/home/yaojian/Codes/Function'));

% Validate mode selection
if ~strcmp(mode, 'Between recording and shuffle') && ~strcmp(mode, 'Between recordings')
    error('Invalid mode selection. Use either ''Between recording and shuffle'' or ''Between recordings''.');
end

% Execute selected analysis mode
switch mode
    case 'Between recording and shuffle'
        % Extract inputs
        RecordingResults = data1;
        ShuffleNullDistribution = data2;

        % Initialize output variables
        IsPutaSig = zeros(BinNum,BinNum);
        ClusBasedPermuTestSigTime = cell(BinNum,1);
        IsPutaSigLessThanChance = zeros(BinNum,BinNum);
        ClusBasedPermuTestSigLessThanChanceTime = cell(BinNum,1);
        ShuffleIsPutaSig = zeros(ShuffleTimes,BinNum,BinNum);
        ShuffleIsPutaSigLessThanChance = zeros(ShuffleTimes,BinNum,BinNum);
        ShufflePutaSigClusSize = zeros(BinNum,ShuffleDecodingTimes);
        ShufflePutaSigLessThanChanceClusSize = zeros(BinNum,ShuffleDecodingTimes);
        Persistence = zeros(BinNum,1);

        % permutation test
        for iTrainBin = 1:BinNum
            for iTestBin = 1:BinNum
                % One/two-sided permutation test
                if OneOrTwoSidedTest == 1 % One-sided test (higher than chance)
                    temp95Percentile = prctile(ShuffleNullDistribution(:,iTrainBin,iTestBin),95);
                    ShuffleIsPutaSig(ShuffleNullDistribution(:,iTrainBin,iTestBin)>temp95Percentile,iTrainBin,iTestBin) = 1;
                    if RecordingResults(iTrainBin,iTestBin) > temp95Percentile
                        IsPutaSig(iTrainBin,iTestBin) = 1;
                    end
                else % Two-sided test (higher/lower than chance)
                    temp95Percentile = prctile(ShuffleNullDistribution(:,iTrainBin,iTestBin),[97.5 2.5]);
                    ShuffleIsPutaSig(ShuffleNullDistribution(:,iTrainBin,iTestBin)>temp95Percentile(1),iTrainBin,iTestBin) = 1;
                    ShuffleIsPutaSigLessThanChance(ShuffleNullDistribution(:,iTrainBin,iTestBin)<temp95Percentile(2),iTrainBin,iTestBin) = 1;

                    if RecordingResults(iTrainBin,iTestBin) > temp95Percentile(1)
                        IsPutaSig(iTrainBin,iTestBin) = 1;
                    elseif RecordingResults(iTrainBin,iTestBin) < temp95Percentile(2)
                        IsPutaSigLessThanChance(iTrainBin,iTestBin) = 1;
                    end
                end
            end

            % Recording data cluster size (higher than chance)
            [tempRecordingResultsSigClusSize,tempRecordingResultsSigClusID] = SigClusterSize(IsPutaSig(iTrainBin,:));
            
            % Recording data cluster size (lower than chance)
            [tempRecordingResultsSigLessThanChanceClusSize,tempRecordingResultsSigLessThanChanceClusID] = SigClusterSize(IsPutaSigLessThanChance(iTrainBin,:));
            
            % Shuffled data cluster size (higher than chance)
            tempTrainAllShuffleTestIsSig = reshape(ShuffleIsPutaSig(:,iTrainBin,:), ShuffleTimes, BinNum);
            for iShuffle = 1:ShuffleTimes
                [tempAllSigClusterSize,~] = SigClusterSize(tempTrainAllShuffleTestIsSig(iShuffle,:));
                if ~isempty(tempAllSigClusterSize)
                    ShufflePutaSigClusSize(iTrainBin,iShuffle) = max(tempAllSigClusterSize);
                end
            end

            % Shuffled data cluster size (lower than chance)
            tempTrainAllShuffleTestIsSigLessThanChance = reshape(ShuffleIsPutaSigLessThanChance(:,iTrainBin,:), ShuffleTimes, BinNum);
            for iShuffle = 1:ShuffleTimes
                [tempAllSigLessThanChanceClusterSize,~] = SigClusterSize(tempTrainAllShuffleTestIsSigLessThanChance(iShuffle,:));
                if ~isempty(tempAllSigLessThanChanceClusterSize)
                    ShufflePutaSigLessThanChanceClusSize(iTrainBin,iShuffle) = max(tempAllSigLessThanChanceClusterSize);
                end
            end

            % Cluster-based permutation test (higher than chance)
            tempShuffle95PercentileClusSize = prctile(ShufflePutaSigClusSize(iTrainBin,:),95);
            if ~isempty(tempRecordingResultsSigClusSize)
                for iCluster = 1:length(tempRecordingResultsSigClusSize)
                    if tempRecordingResultsSigClusSize(iCluster) > tempShuffle95PercentileClusSize
                        ClusBasedPermuTestSigTime{iTrainBin} = [ClusBasedPermuTestSigTime{iTrainBin} tempRecordingResultsSigClusID{iCluster}];
                    end
                end
                Persistence(iTrainBin) = numel(ClusBasedPermuTestSigTime{iTrainBin});
            end

            % Cluster-based permutation test (lower than chance - two-sided only)
            if OneOrTwoSidedTest ~= 1 && ~isempty(tempRecordingResultsSigLessThanChanceClusSize)
                tempShuffle95PercentileLessThanChanceClusSize = prctile(ShufflePutaSigLessThanChanceClusSize(iTrainBin,:),95);
                for iCluster = 1:length(tempRecordingResultsSigLessThanChanceClusSize)
                    if tempRecordingResultsSigLessThanChanceClusSize(iCluster) > tempShuffle95PercentileLessThanChanceClusSize
                        ClusBasedPermuTestSigLessThanChanceTime{iTrainBin} = [ClusBasedPermuTestSigLessThanChanceTime{iTrainBin} tempRecordingResultsSigLessThanChanceClusID{iCluster}];
                    end
                end
            end
        end

        varargout = {ClusBasedPermuTestSigTime,ClusBasedPermuTestSigLessThanChanceTime,Persistence};

    case 'Between recordings'
        % Initialize output variables
        ClusBasedPermuTestSigTime = [];
        ClusBasedPermuTestSigLessThanChanceTime = [];
        IsPutaSig = zeros(1,BinNum);
        IsPutaSigLessThanChance = zeros(1,BinNum);
        ShuffleIsPutaSig = zeros(ShuffleTimes,BinNum);
        ShuffleIsPutaSigLessThanChance = zeros(ShuffleTimes,BinNum);
        ShufflePutaSigClusSize = zeros(ShuffleTimes,1);
        ShufflePutaSigLessThanChanceClusSize = zeros(ShuffleTimes,1);

        % Recording group difference
        RecordingDiffBetwGroups = mean(data1,1) - mean(data2,1);

        % Generate shuffled group differences
        Data = [data1;data2];
        ShuffleDiffBetwGroups = [];
        for itr = 1:ShuffleTimes
            tempOrder = randperm(size(Data,1));
            tempdata1 = Data(tempOrder(1:size(data1,1)),:);
            tempdata2 = Data(tempOrder(size(data1,1)+1:end),:);
            ShuffleDiffBetwGroups = [ShuffleDiffBetwGroups; mean(tempdata1,1) - mean(tempdata2,1)];
        end

        % two-sided permutation test
        for iBin = 1:BinNum
            temp95Percentile = prctile(ShuffleDiffBetwGroups(:,iBin), [97.5 2.5], 1);
            if RecordingDiffBetwGroups(iBin) > temp95Percentile(1)
                IsPutaSig(iBin) = 1;
            end
            ShuffleIsPutaSig(ShuffleDiffBetwGroups(:,iBin)>temp95Percentile(1),iBin) = 1;
            if RecordingDiffBetwGroups(iBin) < temp95Percentile(2)
                IsPutaSigLessThanChance(iBin) = 1;
            end
            ShuffleIsPutaSigLessThanChance(ShuffleDiffBetwGroups(:,iBin)<temp95Percentile(2),iBin) = 1;
        end

        % Recording data cluster size (higher than chance)
        [RecordingResultsPutaSigClusSize,RecordingResultsPutaSigClusID] = SigClusterSize(IsPutaSig);

        % Recording data cluster size (lower than chance)
        [RecordingResultsPutaSigLessThanChanceClusSize,RecordingResultsPutaSigLessThanChanceClusID] = SigClusterSize(IsPutaSigLessThanChance);

        % Shuffle data cluster size (higher than chance)
        for iShuffle = 1:size(ShuffleDiffBetwGroups,1)
            [tempAllSigClusterSize,~] = SigClusterSize(ShuffleIsPutaSig(iShuffle,:));
            if ~isempty(tempAllSigClusterSize)
                ShufflePutaSigClusSize(iShuffle,1) = max(tempAllSigClusterSize);
            end
        end

        % Shuffle data cluster size (lower than chance)
        for iShuffle = 1:size(ShuffleDiffBetwGroups,1)
            [tempAllSigLessThanChanceClusterSize,~] = SigClusterSize(ShuffleIsPutaSigLessThanChance(iShuffle,:));
            if ~isempty(tempAllSigLessThanChanceClusterSize)
                ShufflePutaSigLessThanChanceClusSize(iShuffle,1) = max(tempAllSigLessThanChanceClusterSize);
            end
        end

        % cluster-based permutation test (higher than chance)
        Shuffle95PercentileClusSize = prctile(ShufflePutaSigClusSize,95);
        if ~isempty(RecordingResultsPutaSigClusSize)
            for iCluster = 1:length(RecordingResultsPutaSigClusSize)
                if RecordingResultsPutaSigClusSize(iCluster) > Shuffle95PercentileClusSize
                    ClusBasedPermuTestSigTime = [ClusBasedPermuTestSigTime RecordingResultsPutaSigClusID{iCluster}];
                end
            end
        end

        % cluster-based permutation test (lower than chance)
        Shuffle95PercentileLessThanChanceClusSize = prctile(ShufflePutaSigLessThanChanceClusSize,95);
        if ~isempty(RecordingResultsPutaSigLessThanChanceClusSize)
            for iCluster = 1:length(RecordingResultsPutaSigLessThanChanceClusSize)
                if RecordingResultsPutaSigLessThanChanceClusSize(iCluster) > Shuffle95PercentileLessThanChanceClusSize
                    ClusBasedPermuTestSigLessThanChanceTime = [ClusBasedPermuTestSigLessThanChanceTime RecordingResultsPutaSigLessThanChanceClusID{iCluster}];
                end
            end
        end

        varargout = {ClusBasedPermuTestSigTime, ClusBasedPermuTestSigLessThanChanceTime};
end

end

