function [outputs] = ClusterBasedPermutationTest(mode, data1,data2,BinNum,ShuffleTimes,OneOrTwoSidedTest)
%   Two operational modes are supported:
%   1. 'Between real and shuffle'
%   2. 'Between reals'
%
%   Syntax:
%   - For 'Between real and shuffle' mode:
%     [IsSig,ClusBasedPermuTestIsSig,ShuffleIsSig,ShuffleSigClusSize,RealDecodingResultsSigClusSize,...
%      RealDecodingResultsSigClusID,IsSigLessThanChance,ClusBasedPermuTestIsSigLessChance,RealDecodingResultsSigLessClusSize] = ...
%          ClusterBasedPermutationTest('Between real and shuffle', RealDecodingResults, ShuffleTCTDecodingNullDistribution, TestBinNum, ShuffleTimes, SingleOrTwoSidesTest)
%
%   - For 'Between reals' mode:
%     [SigTime,SigTimeBelowChance] = ClusterBasedPermutationTest('Between reals', data1, data2)
%
%   Inputs:
%   - mode: 'Between real and shuffle' or 'Between reals' to select analysis type
%   - varargin: Variable input arguments matching the selected mode's requirements
%
%   Outputs:
%   - outputs: Struct/array of outputs

addpath(genpath('/home/yaojian/Codes/Function'));

% Validate mode selection
if ~strcmp(mode, 'Between real and shuffle') && ~strcmp(mode, 'Between reals')
    error('Invalid mode selection. Use either ''Between real and shuffle'' or ''Between reals''.');
end

% Execute selected analysis mode
switch mode
    case 'Between real and shuffle'
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

            % Real data cluster size (higher than chance)
            [tempRealResultsSigClusSize,tempRealResultsSigClusID] = SigClusterSize(IsPutaSig(iTrainBin,:));
            
            % Real data cluster size (lower than chance)
            [tempRealResultsSigLessThanChanceClusSize,tempRealResultsSigLessThanChanceClusID] = SigClusterSize(IsPutaSigLessThanChance(iTrainBin,:));
            
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
            if ~isempty(tempRealResultsSigClusSize)
                for iCluster = 1:length(tempRealResultsSigClusSize)
                    if tempRealResultsSigClusSize(iCluster) > tempShuffle95PercentileClusSize
                        ClusBasedPermuTestSigTime{iTrainBin} = [ClusBasedPermuTestSigTime{iTrainBin} tempRealResultsSigClusID{iCluster}];
                    end
                end
                Persistence(iTrainBin) = numel(ClusBasedPermuTestSigTime{iTrainBin});
            end

            % Cluster-based permutation test (lower than chance - two-sided only)
            if OneOrTwoSidedTest ~= 1 && ~isempty(tempRealResultsSigLessThanChanceClusSize)
                tempShuffle95PercentileLessThanChanceClusSize = prctile(ShufflePutaSigLessThanChanceClusSize(iTrainBin,:),95);
                for iCluster = 1:length(tempRealResultsSigLessThanChanceClusSize)
                    if tempRealResultsSigLessThanChanceClusSize(iCluster) > tempShuffle95PercentileLessThanChanceClusSize
                        ClusBasedPermuTestSigLessThanChanceTime{iTrainBin} = [ClusBasedPermuTestSigLessThanChanceTime{iTrainBin} tempRealResultsSigLessThanChanceClusID{iCluster}];
                    end
                end
            end
        end

        % Package CTD outputs
        outputs = {ClusBasedPermuTestSigTime,ClusBasedPermuTestSigLessThanChanceTime,Persistence};

    case 'Between reals'
        % Initialize output variables
        ClusBasedPermuTestSigTime = [];
        ClusBasedPermuTestSigLessThanChanceTime = [];
        IsPutaSig = zeros(1,BinNum);
        IsPutaSigLessThanChance = zeros(1,BinNum);
        ShuffleIsPutaSig = zeros(ShuffleTimes,BinNum);
        ShuffleIsPutaSigLessThanChance = zeros(ShuffleTimes,BinNum);
        ShufflePutaSigClusSize = zeros(ShuffleTimes,1);
        ShufflePutaSigLessThanChanceClusSize = zeros(ShuffleTimes,1);

        % Real group difference
        RealDiffBetwGroups = mean(data1,1) - mean(data2,1);

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
            if RealDiffBetwGroups(iBin) > temp95Percentile(1)
                IsPutaSig(iBin) = 1;
            end
            ShuffleIsPutaSig(ShuffleDiffBetwGroups(:,iBin)>temp95Percentile(1),iBin) = 1;
            if RealDiffBetwGroups(iBin) < temp95Percentile(2)
                IsPutaSigLessThanChance(iBin) = 1;
            end
            ShuffleIsPutaSigLessThanChance(ShuffleDiffBetwGroups(:,iBin)<temp95Percentile(2),iBin) = 1;
        end

        % Real data cluster size (higher than chance)
        [RecordingResultsPutaSigClusSize,RecordingResultsPutaSigClusID] = SigClusterSize(IsPutaSig);

        % Real data cluster size (lower than chance)
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

        % Package outputs
        outputs = {ClusBasedPermuTestSigTime, ClusBasedPermuTestSigLessThanChanceTime};
end

% Convert output cell array to individual outputs
if nargout > 0
    [outputs{1:nargout}] = deal(outputs{:});
end
end

