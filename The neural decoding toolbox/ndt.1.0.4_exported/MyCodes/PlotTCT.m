%this code was used to plot cross-temporal decoding and perform cluster-based permutation test
%PlotNDTDecodingResultsPermutationTest CompareMultipleDecodingResults
%PlotTCTDecodingPermutationTest PlotTCTTargetBin CompareTCTDiff PlotDiffTCT
%PlotCQTCTDecoding CompareTwoTCTDiff PlotCQDecodingResults 
clear;clc;close all;
ColorBarRange=[30 80];
ColorBarRangeMarker=num2str(ColorBarRange);
ColorBarRangeMarker=strrep(ColorBarRangeMarker,'  ','-');
FigureSize=[0.65 0.6];

AllDecodingFile=dir('*CrossTemporalDecoding*.mat');%
%AllDecodingFile=dir('*DiffTCTWithPermuTest*.mat');
for i=1:size(AllDecodingFile,1)
    load(AllDecodingFile(i).name)
    Filename=AllDecodingFile(i).name;
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
    AddIndex=regexpi(Filename,'-Add');
    AddGroupID=Filename(AddIndex:AddIndex+13);
    if isempty(AddIndex)
        AddIndex=regexpi(Filename,'-NonSelec');
        AddGroupID=Filename(AddIndex:AddIndex+12);
    end
    DayID=[];
    DayMarker=regexpi(Filename,'-Day');
    if ~isempty(DayMarker)
        DayID=Filename(DayMarker:end-4);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% plot Cross temporal decoding results with marker for significant time bin
    if exist('RealDataDiffDecoding','var')
        RealDecodingResults=RealDataDiffDecoding;
        ColorRange=[-20 20];
    else
        ColorRange=ColorBarRange;
        if ColorRange(1)>=35
%             Color=[255 255 255]/255;
             Color=[237 30 121]/255;
        else
            Color=[255 255 255]/255;
%             Color=[237 30 121]/255;
        end
    end
    imagesc(X,X,RealDecodingResults*100,ColorRange);%[45 85]
    hold on
    % extract and plot the boundary (X axis) of significant decoding in each training time line(Y axis)
    AllIsSignificantMatrix=zeros(size(RealDecodingResults));
    %     PlotSigStartBin=(4-StartTime-1)*10+1;
    %     PlotSigEndBin=length(find(X<=7));
    %     PlotSigBinRange=PlotSigStartBin:PlotSigEndBin;
    PlotSigBinNum=length(find(X<=11));
    PlotSigBinRange=1:PlotSigBinNum;
    AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)=AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)...
        +ClusterBasedPermuTestIsSignificant(PlotSigBinRange,PlotSigBinRange);
    
    contour(X,X,AllIsSignificantMatrix,[1 1],'-','color',Color,'linewidth',2)
    significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
    for iEvent = 1:length(significant_event_times)
        plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)
        plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
    end
    colorbar('ytick',[40 50 60 70 80],'yticklabel',[40 50 60 70 80])
    set(gca,'xtick',[0 2 4 6 8 10 12 14], 'XTickLabel', [0 2 4 6 8 10 12 14],'ytick',[0 2 4 6 8 10 12 14], 'yTickLabel', [0 2 4 6 8 10 12 14],'TickLength',[0.025, 0.025],'linewidth',1);%add by CQ
%     axis([-3.5 9.2 -3.5 9.2])
    axis([-0.5 DelayMN+OdorMN*2+0.5 -0.5 DelayMN+OdorMN*2+0.5])
    xlabel('Test time (s)','fontsize',12)
    ylabel('Train time (s)','fontsize',12)
    axis xy
    title(TitleName)
%     saveas(gcf,[TitleName '-' ColorBarRangeMarker],'fig')%
%     saveas(gcf,[TitleName '-' ColorBarRangeMarker],'png')%    
    
    TestPeriod=[0 7];
    StartBin=find(X>=TestPeriod(1),1);
    EndBin=find(X<TestPeriod(2), 1, 'last' );
    PlotSigBinRange=StartBin:EndBin;
    
    X1=X(PlotSigBinRange);
    SignificantBinNum=zeros(1,EndBin-StartBin+1);
    SigBinID=cell(1,EndBin-StartBin+1);
    for iTrainBin=StartBin:EndBin
        SignificantBinNum(1,iTrainBin-StartBin+1)=length(find(AllIsSignificantMatrix(iTrainBin,PlotSigBinRange)==1));
        SigBinID{iTrainBin-StartBin+1}=find(AllIsSignificantMatrix(iTrainBin,PlotSigBinRange)==1);
    end
    SignificantBinNum=SignificantBinNum*step_size/1000;    
    
    MarkerBin=[20 35 53];     
    for j=1:length(MarkerBin)
        tempSigBinID=SigBinID{MarkerBin(j)};
        MinBin=min(tempSigBinID);
        MaxBin=max(tempSigBinID);        
        plot([X1(MinBin) X1(MaxBin)],[X1(MarkerBin(j)) X1(MarkerBin(j))],'color',[0 0 1])        
    end
    ResizeFigureForPaper([TitleName '-' ColorBarRangeMarker '-Contour'],[0.66 0.61],[-0.5 DelayMN+OdorMN*2+0.5 -0.5 DelayMN+OdorMN*2+0.5],0,[-2 0 2 4 6 8],[-2 0 2 4 6 8])%[1.361 1.3]
    close all
     
%     %% save in specific size for Adobe Illustrator
%     ResizeFigureForPaper([TitleName '-' ColorBarRangeMarker],FigureSize,[-0.5 7.2 -0.5 7.2],1,[-2 0 2 4 6 8],[-2 0 2 4 6 8])%[1.361 1.3]
%     close all
end