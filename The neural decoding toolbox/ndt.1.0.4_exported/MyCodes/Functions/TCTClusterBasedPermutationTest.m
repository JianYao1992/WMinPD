function [IsSignificant,ClusterBasedPermuTestIsSignificant,ShuffleIsSignificant,ShuffleSigClusterSize...
    ,RealDecodingResultsSigClusterSize,RealDecodingResultsSigClusterID]=TCTClusterBasedPermutationTest(RealDecodingResults...
    ,ShuffleTCTDecodingNullDistribution,TestBinNum,ShuffleDecodingTimes)

IsSignificant=zeros(TestBinNum,TestBinNum);
ClusterBasedPermuTestIsSignificant=zeros(TestBinNum,TestBinNum);
ShuffleIsSignificant=zeros(ShuffleDecodingTimes,TestBinNum,TestBinNum);
ShuffleSigClusterSize=zeros(TestBinNum,ShuffleDecodingTimes);
RealDecodingResultsSigClusterSize=cell(TestBinNum,1);
RealDecodingResultsSigClusterID=cell(TestBinNum,1);
for iTrainBin=1:TestBinNum
    for iTestBin = 1:TestBinNum
        %% permutation test
        temp95Percentile= prctile(ShuffleTCTDecodingNullDistribution(:,iTrainBin,iTestBin),95);
        ShuffleIsSignificant(ShuffleTCTDecodingNullDistribution(:,iTrainBin,iTestBin)>temp95Percentile,iTrainBin,iTestBin)=1;
        if RealDecodingResults(iTrainBin,iTestBin)>temp95Percentile
            IsSignificant(iTrainBin,iTestBin)=1;
        end
        %temp=find(ShuffleTCTDecodingNullDistribution(:,iTrainBin,iTestBin)>temp95Percentile);
    end
    %% Calculate the maximum summed cluster size for real decoding results with specific training point
    tempTrainIsSignificant=IsSignificant(iTrainBin,:);
    tempSigClusterSize=0;
    tempSigClusterID=[];
    for iTestBin = 2:TestBinNum%go through each test bin
        if iTestBin==2&&tempTrainIsSignificant(iTestBin-1)==1
            tempSigClusterSize=1;
            tempSigClusterID=[tempSigClusterID 1];
        end
        if tempTrainIsSignificant(iTestBin)==1&&tempTrainIsSignificant(iTestBin-1)==1
            tempSigClusterSize=tempSigClusterSize+1;
            tempSigClusterID=[tempSigClusterID iTestBin];
            if iTestBin==TestBinNum
                RealDecodingResultsSigClusterSize{iTrainBin}=[RealDecodingResultsSigClusterSize{iTrainBin} tempSigClusterSize];
                RealDecodingResultsSigClusterID{iTrainBin}=[RealDecodingResultsSigClusterID{iTrainBin} {tempSigClusterID}];
            end
        elseif tempTrainIsSignificant(iTestBin)==1&&tempTrainIsSignificant(iTestBin-1)==0
            tempSigClusterSize=1;
            tempSigClusterID=iTestBin;
        else
            if tempSigClusterSize>0
                RealDecodingResultsSigClusterSize{iTrainBin}=[RealDecodingResultsSigClusterSize{iTrainBin} tempSigClusterSize];
                RealDecodingResultsSigClusterID{iTrainBin}=[RealDecodingResultsSigClusterID{iTrainBin} {tempSigClusterID}];
            end
            tempSigClusterSize=0;
            tempSigClusterID=[];
        end
    end
    %% Calculate the maximum summed cluster size for each shuffle decoding with specific training point
    tempTrainAllShuffleTestIsSignificant=ShuffleIsSignificant(:,iTrainBin,:);
    Size=size(tempTrainAllShuffleTestIsSignificant);
    tempTrainAllShuffleTestIsSignificant=reshape(tempTrainAllShuffleTestIsSignificant,Size(1),Size(3));
    for iShuffle=1:ShuffleDecodingTimes
        ShuffletempTrainIsSignificant=tempTrainAllShuffleTestIsSignificant(iShuffle,:);
        tempSigClusterSize=0;
        tempAllSigClusterSize=0;
        for iTestBin = 2:TestBinNum
            if iTestBin==2&&ShuffletempTrainIsSignificant(iTestBin-1)==1
                tempSigClusterSize=1;
            end
            if ShuffletempTrainIsSignificant(iTestBin)==1&&ShuffletempTrainIsSignificant(iTestBin-1)==1
                tempSigClusterSize=tempSigClusterSize+1;
            elseif ShuffletempTrainIsSignificant(iTestBin)==1&&ShuffletempTrainIsSignificant(iTestBin-1)==0
                tempSigClusterSize=1;
            else
                if tempSigClusterSize>0
                    tempAllSigClusterSize=[tempAllSigClusterSize tempSigClusterSize];
                end
                tempSigClusterSize=0;
            end
        end
        ShuffleSigClusterSize(iTrainBin,iShuffle)=max(tempAllSigClusterSize);
    end
    %% perform cluster-based permutation test
    ShuffleSigClusterSizeNullDis=ShuffleSigClusterSize(iTrainBin,:);
    tempShuffle95PercentileCluterSize=prctile(ShuffleSigClusterSizeNullDis,95);
    tempRealDecodingResultsSigClusterSize=RealDecodingResultsSigClusterSize{iTrainBin};
    tempRealDecodingResultsSigClusterID=RealDecodingResultsSigClusterID{iTrainBin};
    if ~isempty(tempRealDecodingResultsSigClusterSize)
        for iCluster=1:length(tempRealDecodingResultsSigClusterSize)
            if tempRealDecodingResultsSigClusterSize(iCluster)>tempShuffle95PercentileCluterSize%exceed the 95th percentile of shuffle data
                ClusterBasedPermuTestIsSignificant(iTrainBin,tempRealDecodingResultsSigClusterID{iCluster})=1;
            end
        end
    end
end