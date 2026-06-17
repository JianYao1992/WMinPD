%this code was used to plot cross-temporal decoding and perform cluster-based permutation test
%PlotNDTDecodingResultsPermutationTest CompareMultipleDecodingResults
%PlotTCTTargetBin PlotTCT CompareTwoDecodingResultsPermTestDiff NDTDecoding
%AllUnitsOdorSelectivityAna PlotCQTCTDecoding
clear;clc;close all;

DecodingTimes=50;
ShuffleDecodingTimes=1000;
IsClusterBasedPermationTest=1;%0 for permutation test without cluster correction

CurrentPath=pwd;
AllPath=genpath(CurrentPath);
SplitPath=strsplit(AllPath,';');
SubPath=SplitPath';
SubPath=SubPath(1:end-1);
SubPath=ExcludeShuffleDir(SubPath);
for iPath=1:size(SubPath,1)%go through each directory
    Path=SubPath{iPath,1};
    cd(Path);
    
    AllDecodingFile=dir('*NDT*.mat');%Parameters.mat
    if exist('Shuffle','dir')==7
        ShuffleDecodingDir='Shuffle';
    else
        ShuffleDecodingDir=[];
    end
    AllParametersDecodingFile=dir('*Parameters*.mat');%
    if size(AllDecodingFile,1)>0
        load(AllParametersDecodingFile.name)
        Filename=AllParametersDecodingFile.name;
        GroupID='-NL';        
        IsChR=regexpi(Filename,'ChR');
        if ~isempty(IsChR)
            GroupID='-ChR';
        end
        IsNpHR=regexpi(Filename,'NpHR');
        if ~isempty(IsNpHR)
            GroupID='-NpHR';
        end
        PhaseID=[];
        PhaserMarker=regexpi(Filename,'-Phase');
        if ~isempty(PhaserMarker)
            PhaseID=Filename(PhaserMarker:PhaserMarker+7);
        end        
        AddIndex=regexpi(AllParametersDecodingFile.name,'-Add');
        AddGroupID=AllParametersDecodingFile.name(AddIndex:AddIndex+13);
        if isempty(AddIndex)
            AddIndex=regexpi(AllParametersDecodingFile.name,'-NonSelec');
            AddGroupID=AllParametersDecodingFile.name(AddIndex:AddIndex+12);
        end
        DayID=[];
        DayMarker=regexpi(Filename,'-Day');
        if ~isempty(DayMarker)
            DayID=Filename(DayMarker:DayMarker+5);
        end 
        %% extract the real cross temporal decoding results
        RealCrossReSampleDecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;
        RealDecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
        RealTCTDecodingStd=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples;
        TimeBinNumber=size(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results,1);
        if size(AllDecodingFile,1)>5%construct real decoding from multiple files
            [RealCrossReSampleDecodingResults,RealDecodingResults,RealTCTDecodingStd,TimeBinNumber]...
                =ConstruceRealDecodingResults(AllDecodingFile,DecodingTimes);
        end
        %curr_stdev_to_plot =DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples;
        %% construct 1000 time shuffle cross temporal decoding
        ShuffleTCTDecodingNullDistribution=zeros(ShuffleDecodingTimes,TimeBinNumber,TimeBinNumber);
        StartBin=1;%
        EndBin=TimeBinNumber;% 1 second after test odor offset
        TestBinNum=EndBin-StartBin+1;
        IsSignificant=zeros(TestBinNum,TestBinNum);
        ClusterBasedPermuTestIsSignificant=zeros(TestBinNum,TestBinNum);
        ShuffleIsSignificant=zeros(ShuffleDecodingTimes,TestBinNum,TestBinNum);
        ShuffleSigClusterSize=zeros(TestBinNum,ShuffleDecodingTimes);
        RealDecodingResultsSigClusterSize=cell(TestBinNum,1);
        RealDecodingResultsSigClusterID=cell(TestBinNum,1);
        if ~isempty(ShuffleDecodingDir)
            ShuffleTCTDecodingNullDistribution=ConstructShuffleTCTDecoding(ShuffleDecodingDir...
                ,ShuffleDecodingTimes,TimeBinNumber,step_size,StartTime);
            %% create significant bin index from the null_distribution at each time point based on cluster-based permutation test
            [IsSignificant,ClusterBasedPermuTestIsSignificant,ShuffleIsSignificant,ShuffleSigClusterSize...
                ,RealDecodingResultsSigClusterSize,RealDecodingResultsSigClusterID]=TCTClusterBasedPermutationTest(RealDecodingResults...
                ,ShuffleTCTDecodingNullDistribution,TestBinNum,ShuffleDecodingTimes);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% plot Cross temporal decoding results with marker for significant time bin
        %RealDecodingResults1=RealDecodingResults(21:PlotSigBinNum,21:PlotSigBinNum);
        cd(SubPath{1})
        ProceedingBinNum=bin_width/step_size;
        X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
        X=X+ProceedingBinNum*step_size/1000;
        
        imagesc(X,X,RealDecodingResults*100,[45 85]);
        hold on
        % extract and plot the boundary (X axis) of significant decoding in each training time line(Y axis)
        AllIsSignificantMatrix=zeros(size(RealDecodingResults));
        PlotSigBinNum=length(find(X<=7.5));
        if ~isempty(ShuffleDecodingDir)
            if IsClusterBasedPermationTest==1
                AllIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)=AllIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)+ClusterBasedPermuTestIsSignificant(1:PlotSigBinNum,1:PlotSigBinNum);
            else
                AllIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)=AllIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)+IsSignificant(1:PlotSigBinNum,1:PlotSigBinNum);
            end
            contour(X,X,AllIsSignificantMatrix,[1 1],'-w','linewidth',2)
        end
        significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
        for iEvent = 1:length(significant_event_times)
            plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)
            plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
        end
        colorbar('ytick',[0 10 20 30 40 50 60 70 80],'yticklabel',[0 10 20 30 40 50 60 70 80])
        set(gca,'xtick',[0 2 4 6], 'XTickLabel', [0 2 4 6],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6]);%add by CQ
        axis([-0.5 7.2 -0.5 7.2])
        xlabel('Test time (s)','fontsize',12)
        ylabel('Train time (s)','fontsize',12)
        axis xy
        title(TitleName)
        saveas(gcf,TitleName,'fig')%
        saveas(gcf,TitleName,'png')%
        close all
        save(['CrossTemporalDecodingWithPermuTest' GroupID AddGroupID PhaseID DayID],'TitleName','RealDecodingResults'...
            ,'RealTCTDecodingStd','X','ClusterBasedPermuTestIsSignificant','IsSignificant','ShuffleTCTDecodingNullDistribution'...
            ,'bin_width','step_size','ShuffleSigClusterSize','RealDecodingResultsSigClusterSize','RealDecodingResultsSigClusterID'...
            ,'ShuffleDecodingTimes','OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','StartTime','GroupID')
    end
end
cd(SubPath{1})