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
        RealResults = data1;
        ShuffleNullDistribution = data2;

        % Initialize output variables
        IsSig = zeros(BinNum,BinNum);
        ClusBasedPermuTestIsSig = zeros(BinNum,BinNum);
        IsSigLessThanChance = zeros(BinNum,BinNum);
        ClusBasedPermuTestIsSigLessChance = zeros(BinNum,BinNum);
        ShuffleIsSig = zeros(ShuffleTimes,BinNum,BinNum);
        ShuffleIsSigLessThanChance = zeros(ShuffleTimes,BinNum,BinNum);
        ShuffleSigClusSize = zeros(BinNum,ShuffleDecodingTimes);
        ShuffleSigLessThanChanceClusSize = zeros(BinNum,ShuffleDecodingTimes);
        RealResultsSigClusSize = cell(BinNum,1);
        RealResultsSigLessThanChanceClusSize = cell(BinNum,1);
        RealResultsSigClusID = cell(BinNum,1);
        RealResultsSigLessThanChanceClusID = cell(BinNum,1);

        % permutation test
        for iTrainBin = 1:BinNum
            for iTestBin = 1:BinNum
                % One/two-sided permutation test
                if OneOrTwoSidedTest == 1 % One-sided test (higher than chance)
                    temp95Percentile = prctile(ShuffleNullDistribution(:,iTrainBin,iTestBin),95);
                    ShuffleIsSig(ShuffleNullDistribution(:,iTrainBin,iTestBin)>temp95Percentile,iTrainBin,iTestBin) = 1;
                    if RealResults(iTrainBin,iTestBin) > temp95Percentile
                        IsSig(iTrainBin,iTestBin) = 1;
                    end
                else % Two-sided test (higher/lower than chance)
                    temp95Percentile = prctile(ShuffleNullDistribution(:,iTrainBin,iTestBin),[97.5 2.5]);
                    ShuffleIsSig(ShuffleNullDistribution(:,iTrainBin,iTestBin)>temp95Percentile(1),iTrainBin,iTestBin) = 1;
                    ShuffleIsSigLessThanChance(ShuffleNullDistribution(:,iTrainBin,iTestBin)<temp95Percentile(2),iTrainBin,iTestBin) = 1;

                    if RealResults(iTrainBin,iTestBin) > temp95Percentile(1)
                        IsSig(iTrainBin,iTestBin) = 1;
                    elseif RealResults(iTrainBin,iTestBin) < temp95Percentile(2)
                        IsSigLessThanChance(iTrainBin,iTestBin) = 1;
                    end
                end
            end

            % Real data cluster size (higher than chance)
            [tempRealResultsSigClusSize,tempRealResultsSigClusID] = SigClusterSize(IsSig(iTrainBin,:));
            RealResultsSigClusSize{iTrainBin} = tempRealResultsSigClusSize;
            RealResultsSigClusID{iTrainBin} = tempRealResultsSigClusID;

            % Real data cluster size (lower than chance)
            [tempRealResultsSigLessThanChanceClusSize,tempRealResultsSigLessThanChanceClusID] = SigClusterSize(IsSigLessThanChance(iTrainBin,:));
            RealResultsSigLessThanChanceClusSize{iTrainBin} = tempRealResultsSigLessThanChanceClusSize;
            RealResultsSigLessThanChanceClusID{iTrainBin} = tempRealResultsSigLessThanChanceClusID;

            % Shuffled data cluster size (higher than chance)
            tempTrainAllShuffleTestIsSig = reshape(ShuffleIsSig(:,iTrainBin,:), ShuffleTimes, BinNum);
            for iShuffle = 1:ShuffleTimes
                [tempAllSigClusterSize,~] = SigClusterSize(tempTrainAllShuffleTestIsSig(iShuffle,:));
                if ~isempty(tempAllSigClusterSize)
                    ShuffleSigClusSize(iTrainBin,iShuffle) = max(tempAllSigClusterSize);
                end
            end

            % Shuffled data cluster size (lower than chance)
            tempTrainAllShuffleTestIsSigLessThanChance = reshape(ShuffleIsSigLessThanChance(:,iTrainBin,:), ShuffleTimes, BinNum);
            for iShuffle = 1:ShuffleTimes
                [tempAllSigLessThanChanceClusterSize,~] = SigClusterSize(tempTrainAllShuffleTestIsSigLessThanChance(iShuffle,:));
                if ~isempty(tempAllSigLessThanChanceClusterSize)
                    ShuffleSigLessThanChanceClusSize(iTrainBin,iShuffle) = max(tempAllSigLessThanChanceClusterSize);
                end
            end

            % Cluster-based permutation test (higher than chance)
            tempShuffle95PercentileClusSize = prctile(ShuffleSigClusSize(iTrainBin,:),95);
            if ~isempty(tempRealResultsSigClusSize)
                for iCluster = 1:length(tempRealResultsSigClusSize)
                    if tempRealResultsSigClusSize(iCluster) > tempShuffle95PercentileClusSize
                        ClusBasedPermuTestIsSig(iTrainBin,tempRealResultsSigClusID{iCluster}) = 1;
                    end
                end
            end

            % Cluster-based permutation test (lower than chance - two-sided only)
            if OneOrTwoSidedTest ~= 1 && ~isempty(tempRealResultsSigLessThanChanceClusSize)
                tempShuffle95PercentileLessThanChanceClusSize = prctile(ShuffleSigLessThanChanceClusSize(iTrainBin,:),95);
                for iCluster = 1:length(tempRealResultsSigLessThanChanceClusSize)
                    if tempRealResultsSigLessThanChanceClusSize(iCluster) > tempShuffle95PercentileLessThanChanceClusSize
                        ClusBasedPermuTestIsSigLessChance(iTrainBin,tempRealResultsSigLessThanChanceClusID{iCluster}) = 1;
                    end
                end
            end
        end

        % Package CTD outputs
        outputs = {IsSig, ClusBasedPermuTestIsSig, ShuffleIsSig, ShuffleSigClusSize, ...
            RealResultsSigClusSize, RealResultsSigClusID, ...
            IsSigLessThanChance, ClusBasedPermuTestIsSigLessChance, ShuffleIsSigLessThanChance, ShuffleSigLessThanChanceClusSize, ...
            RealResultsSigLessThanChanceClusSize, RealResultsSigLessThanChanceClusID};

    case 'Between reals'
        % Initialize output variables
        SigTime_Real = [];
        SigLessThanChanceTime_Real = [];
        IsSig = zeros(1,BinNum);
        IsSigLessThanChance = zeros(1,BinNum);
        ShuffleIsSig = zeros(ShuffleTimes,BinNum);
        ShuffleIsSigLessThanChance = zeros(ShuffleTimes,BinNum);
        ShuffleSigClusSize = zeros(ShuffleTimes,1);
        ShuffleSigLessThanChanceClusSize = zeros(ShuffleTimes,1);

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
                IsSig(iBin) = 1;
            end
            ShuffleIsSig(ShuffleDiffBetwGroups(:,iBin)>temp95Percentile(1),iBin) = 1;
            if RealDiffBetwGroups(iBin) < temp95Percentile(2)
                IsSigLessThanChance(iBin) = 1;
            end
            ShuffleIsSigLessThanChance(ShuffleDiffBetwGroups(:,iBin)<temp95Percentile(2),iBin) = 1;
        end

        % Real data cluster size (higher than chance)
        [RealResultsSigClusSize,RealResultsSigClusID] = SigClusterSize(IsSig);

        % Real data cluster size (lower than chance)
        [RealResultsSigLessThanChanceClusSize,RealResultsSigLessThanChanceClusID] = SigClusterSize(IsSigLessThanChance);

        % Shuffle data cluster size (higher than chance)
        for iShuffle = 1:size(ShuffleDiffBetwGroups,1)
            [tempAllSigClusterSize,~] = SigClusterSize(ShuffleIsSig(iShuffle,:));
            if ~isempty(tempAllSigClusterSize)
                ShuffleSigClusSize(iShuffle,1) = max(tempAllSigClusterSize);
            end
        end

        % Shuffle data cluster size (lower than chance)
        for iShuffle = 1:size(ShuffleDiffBetwGroups,1)
            [tempAllSigLessThanChanceClusterSize,~] = SigClusterSize(ShuffleIsSigLessThanChance(iShuffle,:));
            if ~isempty(tempAllSigLessThanChanceClusterSize)
                ShuffleSigLessThanChanceClusSize(iShuffle,1) = max(tempAllSigLessThanChanceClusterSize);
            end
        end

        % cluster-based permutation test (higher than chance)
        Shuffle95PercentileClusSize = prctile(ShuffleSigClusSize,95);
        if ~isempty(RealResultsSigClusSize)
            for iCluster = 1:length(RealResultsSigClusSize)
                if RealResultsSigClusSize(iCluster) > Shuffle95PercentileClusSize
                    SigTime_Real = [SigTime_Real RealResultsSigClusID{iCluster}];
                end
            end
        end

        % cluster-based permutation test (lower than chance)
        Shuffle95PercentileLessThanChanceClusSize = prctile(ShuffleSigLessThanChanceClusSize,95);
        if ~isempty(RealResultsSigLessThanChanceClusSize)
            for iCluster = 1:length(RealResultsSigLessThanChanceClusSize)
                if RealResultsSigLessThanChanceClusSize(iCluster) > Shuffle95PercentileLessThanChanceClusSize
                    SigLessThanChanceTime_Real = [SigLessThanChanceTime_Real RealResultsSigLessThanChanceClusID{iCluster}];
                end
            end
        end

        % Package outputs
        outputs = {SigTime_Real, SigLessThanChanceTime_Real};
end

% Convert output cell array to individual outputs
if nargout > 0
    [outputs{1:nargout}] = deal(outputs{:});
end
end

