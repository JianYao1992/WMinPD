%this code was used to plot cross-temporal decoding and perform cluster-based permutation test
clear;clc;close all;
AllParametersDecodingFile=dir('*Parameters.mat*');
ShuffleDecodingDir='Shuffle';

ShuffleDecodingTimes=500;
IsClusterBasedPermationTest=1;%0 for permutation test without cluster correction

if size(AllParametersDecodingFile,1)>0
    load(AllParametersDecodingFile.name)
    
    if ~isempty(regexpi(AllParametersDecodingFile.name,'NpHR'))
        PostFix='-NpHR';
    else
        PostFix=[];
    end
    %% extract the real cross temporal decoding results
    RealCrossReSampleDecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;
    RealDecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
    RealTCTDecodingStd=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples;
    TimeBinNumber=size(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results,1);
    %curr_stdev_to_plot =DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples;
    %% construct 1000 time shuffle cross temporal decoding
    ShuffleTCTDecodingNullDistribution=zeros(ShuffleDecodingTimes,TimeBinNumber,TimeBinNumber);
    Path=pwd;
    cd([Path '\' ShuffleDecodingDir])
    ShuffleDecodingFiles=dir('*.mat*');
    StartDecodingTime=0;
    for iShuffleTCTDecoding=1:size(ShuffleDecodingFiles,1)
        load(ShuffleDecodingFiles(iShuffleTCTDecoding).name)
        
        tempShuffleTCTDecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;
        tempShuffleTCTDecodingResults=mean(tempShuffleTCTDecodingResults,2);
        Size=size(tempShuffleTCTDecodingResults);
        tempShuffleTCTDecodingResults=reshape(tempShuffleTCTDecodingResults,Size(1),Size(3),Size(4));
        if StartDecodingTime+Size(1)>ShuffleDecodingTimes
            EndDecodingTime=ShuffleDecodingTimes;
        else
            EndDecodingTime=StartDecodingTime+Size(1); 
        end
        tempDecodingTimes=EndDecodingTime-StartDecodingTime;        
        ShuffleTCTDecodingNullDistribution(StartDecodingTime+1:EndDecodingTime,:,:)=tempShuffleTCTDecodingResults(1:tempDecodingTimes,:,:);
        StartDecodingTime=StartDecodingTime+Size(1);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% create significant bin index from the null_distribution at each time point based on cluster-based permutation test
    StartBin=1;%
    EndBin=TimeBinNumber;% 1 second after test odor offset
    TestBinNum=EndBin-StartBin+1;
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
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    cd(Path)
    %% plot Cross temporal decoding results with marker for significant time bin
    ProceedingBinNum=bin_width/step_size;
    X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-2)-step_size/1000;
    X=X+ProceedingBinNum*step_size/1000;    
    
    imagesc(X,X,RealDecodingResults*100,[40 85]);
    hold on    
    % extract and plot the boundary (X axis) of significant decoding in each training time line(Y axis)
    AllIsSignificantMatrix=zeros(size(RealDecodingResults));  
    TestBinNum=85;
    if IsClusterBasedPermationTest==1        
        AllIsSignificantMatrix(1:TestBinNum,1:TestBinNum)=AllIsSignificantMatrix(1:TestBinNum,1:TestBinNum)+ClusterBasedPermuTestIsSignificant(1:TestBinNum,1:TestBinNum);
        PostFix1=['-ClusterBasedPermutationTest-' num2str(ShuffleDecodingTimes)];                
    else
        PostFix1=['-PermutationTest-' num2str(ShuffleDecodingTimes)];
        AllIsSignificantMatrix(1:TestBinNum,1:TestBinNum)=AllIsSignificantMatrix(1:TestBinNum,1:TestBinNum)+IsSignificant(1:TestBinNum,1:TestBinNum);    
    end
    significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
    for iEvent = 1:length(significant_event_times)
        line([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'), 'color', [0 0 0])
        line(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)], 'color', [0 0 0])
    end
    colorbar
    set(gca,'xtick',[0 1 2 3 4 5 6 10], 'XTickLabel', [0 1 2 3 4 5 6 10],'ytick',[0 1 2 3 4 5 6 10], 'yTickLabel', [0 1 2 3 4 5 6 10]);%add by CQ
    axis xy
    contour(X,X,AllIsSignificantMatrix,[1 1],'-w','linewidth',2)
    axis([-1 8 -1 8])    
    xlabel('Test time (s)','fontsize',12)
    ylabel('Train time(s)','fontsize',12)
    title([TitleName PostFix1])
    saveas(gcf,[TitleName '-Cross-temporal decoding' PostFix1],'fig')%
    saveas(gcf,[TitleName '-Cross-temporal decoding' PostFix1],'png')%
    close all    
    save(['CrossTemporalDecodingWithPermuTest' PostFix PostFix1],'TitleName','RealDecodingResults','RealTCTDecodingStd','X'...
        ,'ClusterBasedPermuTestIsSignificant','IsSignificant','ShuffleTCTDecodingNullDistribution','bin_width','step_size'...
        ,'ShuffleSigClusterSize','RealDecodingResultsSigClusterSize','RealDecodingResultsSigClusterID','ShuffleDecodingTimes'...
        ,'OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN')
end