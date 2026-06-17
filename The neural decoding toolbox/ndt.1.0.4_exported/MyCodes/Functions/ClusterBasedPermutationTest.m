function TimeLampsedIsSignificant=ClusterBasedPermutationTest(RealDecodingResults,null_distributions...
    ,IsClusterBasedPermationTest,ShuffleDecodingTimes)

TestBinNum=size(RealDecodingResults,2);
if IsClusterBasedPermationTest==1%Cluster based permutation test
    %% Judge the significance of each bin, based on 95 percentile both for real and shuffle decoding resutls
    IsSignificant=zeros(1,TestBinNum);
    ShuffleIsSignificant=zeros(ShuffleDecodingTimes,TestBinNum);
    All95Percentile=zeros(1,TestBinNum);
    for iTestBin = 1:TestBinNum% go through each bin
        temp95Percentile= prctile(null_distributions(:,iTestBin),95);
        All95Percentile(iTestBin)=temp95Percentile;
        ShuffleIsSignificant(null_distributions(:,iTestBin)>temp95Percentile,iTestBin)=1;
        if RealDecodingResults(iTestBin)>temp95Percentile
            IsSignificant(1,iTestBin)=1;
        end
    end
    %% calculate real decoding significant cluster size
    [RealDecodingResultsSigClusterSize,RealDecodingResultsSigClusterBinID]=CalculateSignificantClusterSize(IsSignificant);
    %% calculate shuffle decoding significant cluster size
    ShuffleSigClusterSizeNullDis=zeros(ShuffleDecodingTimes,1);
    for iShuffle=1:size(null_distributions,1)% go through each shuffle
        [tempShuffleSigClusterSize,~]=CalculateSignificantClusterSize(ShuffleIsSignificant(iShuffle,:));
        if ~isempty(tempShuffleSigClusterSize)
            ShuffleSigClusterSizeNullDis(iShuffle)=max(tempShuffleSigClusterSize);
        end
    end
    %% perform cluster-based(for significant bin) permutation test 
    Shuffle95PercentileSigCluterSize=prctile(ShuffleSigClusterSizeNullDis,95);
    ClusterBasedPermuTestIsSignificant=zeros(1,TestBinNum);
    if ~isempty(RealDecodingResultsSigClusterSize)
        for iCluster=1:length(RealDecodingResultsSigClusterSize)%go through each significant cluster in real decoding results
            if RealDecodingResultsSigClusterSize(iCluster)>Shuffle95PercentileSigCluterSize%exceed the 95th percentile of shuffle data
                ClusterBasedPermuTestIsSignificant(1,RealDecodingResultsSigClusterBinID{iCluster})=1;
            end
        end
    end
    TimeLampsedIsSignificant=ClusterBasedPermuTestIsSignificant;
else
    PermuTestIsSignificant=zeros(1,TestBinNum);
    for iBin = 1:TestBinNum
        p1 = length(find(null_distributions(:, iBin) <  RealDecodingResults(iBin)))./size(null_distributions, 1);%permutation test
        p2 = length(find(null_distributions(:, iBin) >= RealDecodingResults(iBin)))./size(null_distributions, 1);
        if min([p1 p2])<0.005            
            PermuTestIsSignificant(iBin)=1;
        end
    end
    TimeLampsedIsSignificant=PermuTestIsSignificant;
end