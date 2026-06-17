%this code was used to plot temporal cross-training(TCT) decoding results for specific bin
% addpath(genpath('D:\CQ\Matlab codes'))
clear;clc;close all;
%PlotTCTTargetBin PlotTCT PlotTCTDecodingPermutationTest %DiffNeuGroupContriInTCTDecoding
DecodingResults=dir('*CrossTemporalDecoding*.mat');

ColorBarRange=[40 85];
ColorBarRangeMarker=num2str(ColorBarRange);
ColorBarRangeMarker=strrep(ColorBarRangeMarker,'  ','-');

Colors=[[19 130 197]/255;[0 0 0];[19 156 78]/255;[1 0 1]];
AreaColors=[[113 180 220];[128 128 128];[113 196 149]]/255;
AllTargetTimeBin=[0 0.5 1 1.5 2 2.5 3 3.5 4 4.5 5 5.5 6 100];%
% AllTargetTimeBin=[100];%

Legends=[{'ChR'};{'NL'};{'NpHR'}];
Title='Laser effects on TCT decoding';
GroupID=[];
% Legends=[{'Phase1'};{'Phase2'};{'Phase3'}];
% Title='Per dependent TCT decoding';
% Legends=[{'Day1'};{'Day2'};{'Day3'};{'Day4-5'}];
% Title='Learning effects on TCT decoding';
%Legends=[{'NonSelectNeu'};{'Add1SigBinNeu'};{'Add2SigBinNeu'};{'Add3SigBinNeu'};{'Add4SigBinNeu'};{'Add5SigBinNeu'}];
% Legends=[{'Add1SigBinNeu'};{'Add3SigBinNeu'};{'Add5SigBinNeu'}];
% Title='Sustained neuron effects on TCT decoding';
% Colors = [[0 0 0];[0.7 0.7 1];[0.3 0.3 1];[0 0 1];[1 0.5 0.5];[1 0 0]];
% Colors = [[0 0 0];[0.7 0.7 1];[0.3 0.3 1];[0 0 1];[1 0.5 0.5];[1 0 0]];

CrossGroupBinNum=zeros(1,size(DecodingResults,1));
TotalDecodingResults=cell(3,size(DecodingResults,1));
for iCondiction=1:size(DecodingResults,1)
    load(DecodingResults(iCondiction).name)
    
    TotalDecodingResults{1,iCondiction}=RealDecodingResults;%(StartBin:EndBin,StartBin:EndBin)
    TotalDecodingResults{2,iCondiction}=RealTCTDecodingStd;%(StartBin:EndBin,StartBin:EndBin)
    TotalDecodingResults{3,iCondiction}=ClusterBasedPermuTestIsSignificant;% (StartBin:EndBin,StartBin:EndBin)
    CrossGroupBinNum(1,iCondiction)=size(RealDecodingResults,2);
end
MinBinNum=min(CrossGroupBinNum);
X=X(1:MinBinNum);
MinBinNum=repmat({MinBinNum},size(TotalDecodingResults));
TotalDecodingResults=cellfun(@(x,y) x(1:y,1:y),TotalDecodingResults,MinBinNum,'uniformoutput',0);

significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
%%
DayID=[];
DayMarker=regexpi(DecodingResults(1).name,'Day');
if ~isempty(DayMarker)
    DayID=DecodingResults(iCondiction).name(DayMarker:end-4);
end
if size(DecodingResults,1)==3
    figure('position',[300 300 1200,450])
elseif size(DecodingResults,1)==4
    figure('position',[250 200 1200,450])
elseif size(DecodingResults,1)==2
    figure('position',[250 200 1000,450])
end
for i=1:size(DecodingResults,1)
    if size(DecodingResults,1)==3
        subplot('position',[0.08+(i-1)*0.3,0.12,0.26,0.78]);%[left bottom width height]
    elseif size(DecodingResults,1)==4
        subplot('position',[0.06+(i-1)*0.23,0.09,0.2,0.78]);%[left bottom width height]
    elseif size(DecodingResults,1)==2
        subplot('position',[0.08+(i-1)*0.43,0.09,0.38+(i-1)*0.04,0.78]);%[left bottom width height]    
    end
    imagesc(X,X,TotalDecodingResults{1,i}*100,ColorBarRange);
    hold on
    
    AllIsSignificantMatrix=zeros(size(TotalDecodingResults{1,1}));
%     StartBin=(4-StartTime-1)*10+1;
    StartBin=find(X>=-0.5,1);
    EndBin=length(find(X<=7));
    PlotSigBinRange=StartBin:EndBin;
    AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)=AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)...
        +TotalDecodingResults{3,i}(PlotSigBinRange,PlotSigBinRange);
    if max(max(AllIsSignificantMatrix))>0
        contour(X,X,AllIsSignificantMatrix,[1 1],'-w','linewidth',1)
    end
    for iEvent = 1:length(significant_event_times)
%         line([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'), 'color', [0 0 0])
%         line(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)], 'color', [0 0 0])
        plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)   
        plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
    end
    axis xy
    if size(DecodingResults,1)==3
        if i==3
            colorbar('ytick',[30 40 50 60 70 80],'yticklabel',[30 40 50 60 70 80])
        end
    elseif size(DecodingResults,1)==4
        if i==4
            colorbar('ytick',[50 60 70 80],'yticklabel',[50 60 70 80])
        end
    elseif size(DecodingResults,1)==2
        if i==2
            colorbar('ytick',[50 60 70 80],'yticklabel',[50 60 70 80])
        end
    end
    set(gca,'xtick',[0 2 4 6], 'XTickLabel', [0 2 4 6],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6]);%add by CQ
    axis([-0.5 7.2 -0.5 7.2])
    title(Legends{i},'fontsize',14)
end
saveas(gcf,['CrossTemporalDecoding-' Title GroupID '-' ColorBarRangeMarker],'fig')
saveas(gcf,['CrossTemporalDecoding-' Title GroupID '-' ColorBarRangeMarker],'png')
close all
%% plot the difference of TCT result
ID1=regexpi(TitleName,'-MCC');
ID2=regexpi(TitleName,'-Norm');
DecodingParameters=[TitleName(1:ID1+3) TitleName(ID2:end)];
ROI1Range=[3 6 3 6];
ROI2Range=[1 2 3 6];
ROI3Range=[3 6 1 2];
AllROIs=[{ROI1Range};{ROI2Range};{ROI3Range}];
PlotIndex=find(X>=-0.5&X<=7);
ChRNLDiff=TotalDecodingResults{1,1}-TotalDecodingResults{1,2};
if size(DecodingResults,1)==3
    NpHRNLDiff=TotalDecodingResults{1,3}-TotalDecodingResults{1,2};
    DiffTCT=[{ChRNLDiff};{NpHRNLDiff}];
else
    DiffTCT={ChRNLDiff};
end
Marker=[{'ChR minus NL '};{'NpHR minus NL'}];
if length(DiffTCT)==2
    figure('position',[400 300 900,450])    
    MaxMinDIff=zeros(4,length(PlotIndex));
    for i=1:length(DiffTCT)
        subplot('position',[0.07+(i-1)*0.43,0.09,0.38+(i-1)*0.06,0.78]);%[left bottom width height]
        imagesc(X,X,DiffTCT{i}*100,[-20 20]);
        set(gca,'xticklabel',[])
        hold on
        MaxMinDIff((i-1)*2+1:i*2,:)=[max(DiffTCT{i}(PlotIndex,PlotIndex));min(DiffTCT{i}(PlotIndex,PlotIndex))]*100;
        for iEvent = 1:length(significant_event_times)
            %     line([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'), 'color', [0 0 0])
            %     line(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)], 'color', [0 0 0])
            plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)
            plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
        end
        axis xy
        for j=1:length(AllROIs)%go though each ROI
            tempROI=AllROIs{j};
            X1=[tempROI(3:4) fliplr(tempROI(3:4))];
            Y1=[tempROI(1) tempROI(1) tempROI(2) tempROI(2)];
            patch(X1,Y1,'w','facecolor','none','linestyle','--','linewidth',1.5,'EdgeColor',[1 1 1])            
        end
        if i==length(DiffTCT)
            colorbar('ytick',[-20 -10 0 10 20],'yticklabel',[-20 -10 0 10 20])
        end
        axis([-0.5 7.2 -0.5 7.2])
        set(gca,'xtick',[0 2 4 6], 'XTickLabel', [],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6]);
        title(Marker{i},'fontsize',14)
    end
    saveas(gcf,['Diff-TCT-' DecodingParameters '-' ColorBarRangeMarker],'fig')
    saveas(gcf,['Diff-TCT-' DecodingParameters '-' ColorBarRangeMarker],'png')
    close all
end
%%
for i=1:length(DiffTCT)
    imagesc(X,X,DiffTCT{i}*100,[-20 20]);
    set(gca,'xticklabel',[])
    hold on
    MaxMinDIff((i-1)*2+1:i*2,:)=[max(DiffTCT{i}(PlotIndex,PlotIndex));min(DiffTCT{i}(PlotIndex,PlotIndex))]*100;
    for iEvent = 1:length(significant_event_times)
        %     line([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'), 'color', [0 0 0])
        %     line(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)], 'color', [0 0 0])
        plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)
        plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
    end
    axis xy
    colorbar('ytick',[-20 -10 0 10 20],'yticklabel',[-20 -10 0 10 20])
    axis([-0.5 7.2 -0.5 7.2])
    set(gca,'xtick',[0 2 4 6], 'XTickLabel', [],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6]);
    title(Marker{i},'fontsize',14)
    saveas(gcf,['DiffTCT-' Marker{i} '-' TitleName '-' ColorBarRangeMarker],'fig')
    saveas(gcf,['DiffTCT-' Marker{i} '-' TitleName '-' ColorBarRangeMarker],'png')
    ResizeFigureForPaper(['DiffTCT-' Marker{i} '-' TitleName '-' ColorBarRangeMarker],[1.36 1.3]...
        ,[-0.5 7.2 -0.5 7.2],1,[-2 0 2 4 6 8],[-2 0 2 4 6 8])
    close all
end
%%
SecondColors=[[0 0 1];[0 0 0];[0.2 0.2 0.2];[0.4 0.4 0.4];[0.6 0.6 0.6];[0.8 0.8 0.8];[1 0 1]];%
SecondLegends=[{'Sample'};{'Delay1'};{'Delay2'};{'Delay3'};{'Delay4'};{'Delay5'};{'Test'}];% 
TestPeriod=[0 7];
if max(max(ClusterBasedPermuTestIsSignificant))>0                  
    StartBin=find(X>=TestPeriod(1),1);
    EndBin=find(X<TestPeriod(2), 1, 'last' );
    PlotSigBinRange=StartBin:EndBin;
    SignificantBinNum=zeros(length(DecodingResults),EndBin-StartBin+1);
    for iTrainBin=StartBin:EndBin
        for iCondiction=1:length(DecodingResults)
            SignificantBinNum(iCondiction,iTrainBin-StartBin+1)=length(find(TotalDecodingResults{3,iCondiction}(iTrainBin,PlotSigBinRange)==1));
        end
    end
    SignificantBinNum=SignificantBinNum*step_size/1000;        
    
%     plot(X(PlotSigBinRange),SignificantBinNum(2,:),'-k')
%     hold on
%     X1=X(PlotSigBinRange);
%     MarkerBin=[8 35 55];   
%     for j=1:length(MarkerBin)
%         tempSigBinDuration=SignificantBinNum(2,MarkerBin(j));        
%         plot([X1(MarkerBin(j)) X1(MarkerBin(j))],[0 tempSigBinDuration],'color',[0 0 1])        
%     end
%     EventCurve(OdorMN,DelayMN,ResponseMN,WaterMN,7.5,0,4)
%     axis([-0.5 7.2 0 7.2])
%     ResizeFigureForPaper('A example of NLPersistence',[0.8 0.75]...
%         ,[-0.5 7.2 0 7.2],0,[-2 0 2 4 6 8],[-2 0 2 4 6 8])    
    
    %SignificantBinNum(SignificantBinNum~=0)=SignificantBinNum(SignificantBinNum~=0)+bin_width/1000;
    ChRSignificantBinDuration=SignificantBinNum(1,:);
    NLSignificantBinDuration=SignificantBinNum(2,:);
    NpHRSignificantBinDuration=SignificantBinNum(3,:);
    
    [p1,h1] = signrank(ChRSignificantBinDuration,NLSignificantBinDuration);   
    AddLegend(SecondLegends,SecondColors)
    hold on
    BlockNum=ceil(length(ChRSignificantBinDuration)/10);
    for j=1:BlockNum
%         scatter(NLSignificantBinDuration((j-1)*10+1:j*10),ChRSignificantBinDuration((j-1)*10+1:j*10),[],SecondColors(j,:),'Marker','.','markerfacecolor',SecondColors(j,:))        
        scatter(NLSignificantBinDuration((j-1)*10+1:j*10),ChRSignificantBinDuration((j-1)*10+1:j*10),[],[0 0 0],'Marker','.','markerfacecolor',[0 0 0])        
    end
    hold on
    plot([0 TestPeriod(2)],[0 TestPeriod(2)],'--k')
    text(0.2,TestPeriod(2)-0.2,['p=' num2str(p1)])
    text(0.2,TestPeriod(2)-0.5,['n=' num2str(length(ChRSignificantBinDuration))])
    axis([0 TestPeriod(2) 0 TestPeriod(2)])
    title('The duration of TCT decoding-ChR-NL')
    saveas(gcf,['The duration of TCT decoding-ChR-NL-' Title GroupID '-' ColorBarRangeMarker],'fig')
    saveas(gcf,['The duration of TCT decoding-ChR-NL-' Title GroupID '-' ColorBarRangeMarker],'png')
    ResizeFigureForPaper(['The duration of TCT decoding-ChR-NL-' Title GroupID '-' ColorBarRangeMarker],[0.55 0.55]...
        ,[TestPeriod TestPeriod],0,[-2 0 2 4 6 8],[-2 0 2 4 6 8])
    close all
    %% NpHR VS. NL
    [p2,h2] = signrank(NpHRSignificantBinDuration,NLSignificantBinDuration);   
    AddLegend(SecondLegends,SecondColors)
    hold on
    BlockNum=ceil(length(NpHRSignificantBinDuration)/10);
    for j=1:BlockNum
%         scatter(NLSignificantBinDuration((j-1)*10+1:j*10),NpHRSignificantBinDuration((j-1)*10+1:j*10),[],SecondColors(j,:),'Marker','.','markerfacecolor',SecondColors(j,:))        
        scatter(NLSignificantBinDuration((j-1)*10+1:j*10),NpHRSignificantBinDuration((j-1)*10+1:j*10),[],[0 0 0],'Marker','.','markerfacecolor',[0 0 0])   
    end
    hold on
    plot([0 TestPeriod(2)],[0 TestPeriod(2)],'--k')
    text(0.2,TestPeriod(2)-0.2,['p=' num2str(p2)])
    text(0.2,TestPeriod(2)-0.5,['n=' num2str(length(NpHRSignificantBinDuration))])
    axis([0 TestPeriod(2) 0 TestPeriod(2)])
    title('The duration of TCT decoding-NpHR-NL')
    saveas(gcf,['The duration of TCT decoding-NpHR-NL-' Title GroupID '-' ColorBarRangeMarker],'fig')
    saveas(gcf,['The duration of TCT decoding-NpHR-NL-' Title GroupID '-' ColorBarRangeMarker],'png')
    ResizeFigureForPaper(['The duration of TCT decoding-NpHR-NL-' Title GroupID '-' ColorBarRangeMarker],[0.55 0.55]...
        ,[TestPeriod TestPeriod],0,[-2 0 2 4 6 8],[-2 0 2 4 6 8])%[1 1]
    close all
end
%% plot significant bin number in specific training bin
PlotSigBinRange1=find(X<7.5&X>=-0.5);
NLCrossTimeDecodingAccuracy=zeros(length(AllTargetTimeBin),size(TotalDecodingResults{1,1},2));
for iTrainBin=1:length(AllTargetTimeBin)
    
    TargetTimeBin=AllTargetTimeBin(iTrainBin);
    TargetBinIndex=find(X>=TargetTimeBin,1);
    
    YMax=zeros(1,length(DecodingResults));
    YMin=zeros(1,length(DecodingResults));
    TargetBinTCTDecodingResults=zeros(length(DecodingResults),size(TotalDecodingResults{1,1},2));
    TargetBinTCTDecodingStd=zeros(length(DecodingResults),size(TotalDecodingResults{1,1},2));
    TargetBinIsSignificant=zeros(length(DecodingResults),size(TotalDecodingResults{1,1},2));
    for iCondiction=1:size(DecodingResults,1)
        if TargetTimeBin==100%diagonal, train and test with the same time bin
            TargetBinTCTDecodingResults(iCondiction,:)=diag(TotalDecodingResults{1,iCondiction})';
            TargetBinTCTDecodingStd(iCondiction,:)=diag(TotalDecodingResults{2,iCondiction})';
            TargetBinIsSignificant(iCondiction,:)=diag(TotalDecodingResults{3,iCondiction})';
        else
            TargetBinTCTDecodingResults(iCondiction,:)=TotalDecodingResults{1,iCondiction}(TargetBinIndex,:);
            TargetBinTCTDecodingStd(iCondiction,:)=TotalDecodingResults{2,iCondiction}(TargetBinIndex,:);
            TargetBinIsSignificant(iCondiction,:)=TotalDecodingResults{3,iCondiction}(TargetBinIndex,:);
            if iCondiction==2
                NLCrossTimeDecodingAccuracy(iTrainBin,:)=TotalDecodingResults{1,iCondiction}(TargetBinIndex,:);
            end
        end
        YMax(1,iCondiction)=max(TargetBinTCTDecodingResults(iCondiction,:)+TargetBinTCTDecodingStd(iCondiction,:));
        YMin(1,iCondiction)=min(TargetBinTCTDecodingResults(iCondiction,:)-TargetBinTCTDecodingStd(iCondiction,:));
    end
    
    figure
    AddLegend(Legends,Colors,'northeast')
    hold on
    for iCondiction=1:length(DecodingResults)
        PlotMeanSEM(TargetBinTCTDecodingResults(iCondiction,PlotSigBinRange1),X(PlotSigBinRange1)...
            ,[AreaColors(iCondiction,:);Colors(iCondiction,:)],TargetBinTCTDecodingStd(iCondiction,PlotSigBinRange1));
        for iBin=PlotSigBinRange1
            if TargetBinIsSignificant(iCondiction,iBin)==1
                plot(X(iBin),0.35+iCondiction*0.02,'.','color',Colors(iCondiction,:),'markersize',4)
            end
        end
    end
    EventCurve(OdorMN,DelayMN,ResponseMN,WaterMN,max(YMax),min(YMin));
    plot([-2 max(X)],[0.5 0.5],'--k','linewidth',1)
    xlabel('Time from sample onset(s)','fontsize',14)
    ylabel('Decoding Accuracy','fontsize',14)
    set(gca,'fontsize',14,'TickDir','out')
    axis([-1 7.2 0.35 max(YMax)*1.05])
    if TargetTimeBin==100
        PostFix='Diagonal';
    else
        TimeMarker=num2str(TargetTimeBin);
        TimeMarker=strrep(TimeMarker,'.','-');
        PostFix=[TimeMarker ' second'];
    end
    title(['Train time the ' PostFix],'fontsize',14)
    saveas(gcf,['TCT decoding for sample odor train with the-' PostFix DayID '-' ColorBarRangeMarker],'fig')%
    saveas(gcf,['TCT decoding for sample odor train with the-' PostFix DayID '-' ColorBarRangeMarker],'png')%    
    ResizeFigureForPaper(['TCT decoding for sample odor train with the-' PostFix DayID '-' ColorBarRangeMarker],[1 1],[-0.5 7.2 0.3 1]...
        ,0,[-2 0 2 4 6 8],[0.2 0.4 0.6 0.8 1])
    close all
end