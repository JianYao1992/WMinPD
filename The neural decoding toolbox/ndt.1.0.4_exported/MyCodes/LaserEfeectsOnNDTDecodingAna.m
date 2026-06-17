%Compare the decoding accuracy between laer and no-Laser conditions with
%decoding analysis by using the Neural Decoding Toolbox
%CompareMultipleDecodingResults TrialTypeAndLaserEffecsOnDecoding
clear;clc;close all;
DecodingResultsFiles=dir('*All Parameters*.mat');%NDT
ShuffleDecodingDir=[{'Shuffle NoLaser'};{'Shuffle NpHR'}];
% Legends=[{'ChR2'};{'No-Laser'};{'NpHR'}];
% Legends=[{'TransientNeu'};{'SustainedNeu'};{'SwitchedNeu'}];
 Legends=[{'CorrTrials'};{'ErrorTrials'}];
% Colors=[[19 130 197]/255;[0 0 0];[19 156 78]/255;[1 0 1]];
% AreaColors=[[113 180 220];[128 128 128];[113 196 149]]/255;

Colors=[[0 0 0];[255 0 0]/255;[19 156 78]/255;[1 0 1]];
AreaColors=[[128 128 128];[153 0 0];[113 196 149]]/255;

DecodingTimesToCompare=100;
% ID=regexpi(DecodingResultsFiles(1).name,'Norm');
% ID1=regexpi(DecodingResultsFiles(1).name(ID:end),'-');
% TrialType=DecodingResultsFiles(1).name(ID+5:ID+ID1(2)-2);

DayIndex=regexpi(DecodingResultsFiles(1).name,'Day');
AllParaIndex=regexpi(DecodingResultsFiles(1).name,'All Parameters');
DayID=DecodingResultsFiles(1).name(DayIndex-1:AllParaIndex-1);

IsClusterBasedPermationTest=1;
ShuffleDecodingTimes=1000;
Path=pwd;
figure('color',[1 1 1])
h=zeros(1,size(DecodingResultsFiles,1));
YMax=zeros(1,size(DecodingResultsFiles,1));
YMin=zeros(1,size(DecodingResultsFiles,1));
CrossGroupDecodingResults=cell(1,size(DecodingResultsFiles,1));
StartTime=0;
PlotRange=[-0.5 7.5];
for iResult=1:size(DecodingResultsFiles,1)
    load(DecodingResultsFiles(iResult).name)
    
    if exist('DECODING_RESULTS','var')
        if isstruct(DECODING_RESULTS)
            DecodingAccuracy=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;
            DecodingAccuracy=mean(DecodingAccuracy,2);
            DecodingAccuracy=reshape(DecodingAccuracy,size(DecodingAccuracy,1),size(DecodingAccuracy,3));
        else
            DecodingAccuracy=DECODING_RESULTS;
        end
    end
    CrossGroupDecodingResults{1,iResult}=DecodingAccuracy;
    
    MeanDecodingResults=smooth(mean(DecodingAccuracy(1:DecodingTimesToCompare,:)))';
    STDDecodingAccuracy=std(DecodingAccuracy(1:DecodingTimesToCompare,:));
    %     MeanDecodingResults=smooth(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results)';
    %     STDDecodingAccuracy=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples';
    
    %ProceedingBinNum=bin_width/step_size;
    TimeBinNumber=length(MeanDecodingResults);
%     X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
%     X=X+step_size/1000/2;
%     X=X+(bin_width/step_size-1)*step_size/1000;
    %     X=X+ProceedingBinNum*step_size/1000;
    PlotBinID=find(X>PlotRange(1)&X<PlotRange(2));
    X1=X(PlotBinID);
    %     X=X(PlotBinID);
    %    TimeLampsedIsSignificant=TimeLampsedIsSignificant(PlotBinID);
    %%
    if iResult==1
        AddLegend(Legends,Colors,'southeast')
    end
    %plot std of correct trials decoding results
    [y2,y1]=PlotMeanSEM(MeanDecodingResults(PlotBinID),X1,[AreaColors(iResult,:);Colors(iResult,:)]...
        ,zeros(1,length(PlotBinID)));%STDDecodingAccuracy(:,PlotBinID)
    hold on
    %% cluster-based permutation test
    %         PermutationDecodingResultsDir=[Path '\' ShuffleDecodingDir{iResult} '\'];
    %         null_distributions=CQ_create_nulldist_from_shuffle_files(PermutationDecodingResultsDir);
    %         TimeLampsedIsSignificant=ClusterBasedPermutationTest(MeanDecodingResults,null_distributions...
    %             ,IsClusterBasedPermationTest,ShuffleDecodingTimes);
    if exist('TimeLampsedIsSignificant','var')
        plot(X(TimeLampsedIsSignificant==1),(0.34+iResult*0.02)*ones(1,sum(TimeLampsedIsSignificant)),'.','color',Colors(iResult,:),'markersize',4)
    end
    %plot event information
    YMax(1,iResult)=max(y1);
    YMin(1,iResult)=min(y2);
end
text(OdorMN+0.5,0.55,['UnitNum=' num2str(num_neuron_ForDecoding)],'color',Colors(iResult,:),'fontsize',14)
plot([-3 2*OdorMN+DelayMN+ResponseMN+WaterMN+ITIMN-0.5],[0.5 0.5],'--k','linewidth',1)
EventCurve(OdorMN,DelayMN,ResponseMN,WaterMN,max(YMax),min(YMin));
%%
xlabel('Time from sample onset(s)','fontsize',14)
ylabel('Decoding Accuracy','fontsize',14)
set(gca,'fontsize',14,'TickDir','out')
axis([PlotRange 0.35 1])
box off
title(['Laser effect on decoding results-' DayID '-' num2str(DecodingTimesToCompare)],'fontsize',16)% TrialType
saveas(gcf,['Laser effects on decoding for sample odor-' DayID '-' num2str(DecodingTimesToCompare)],'fig')% TrialType
saveas(gcf,['Laser effects on decoding for sample odor-' DayID '-' num2str(DecodingTimesToCompare)],'png')% TrialType
ResizeFigureForPaper(['Laser effects on decoding for sample odor-' DayID '-' num2str(DecodingTimesToCompare)]...
    ,[1.45 1],[-0.5 7.2 0.3 1],0,[-2 0 2 4 6 8],[0.4 0.6 0.8 1])
% close all
%%
% Delay12=[OdorMN OdorMN+2];
% Delay345=[OdorMN+2 OdorMN+DelayMN];
% WholeDelayPer=[OdorMN OdorMN+DelayMN];
% AllPeriodToPlot=[{Delay12};{Delay345};{WholeDelayPer}];
%
% TimeBinNumber=size(CrossGroupDecodingResults{1,1},2);
% X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
% ProceedingBinNum=bin_width/step_size;
% X=X+ProceedingBinNum*step_size/1000;
%
% DecodingTimes=size(CrossGroupDecodingResults{1,1},1);
% PeriodMarkers=[{'Delay12'};{'Delay345'};{'WholeDelay'}];
% AllPeriodsMeanDecodingAccuracy=cell(1,length(AllPeriodToPlot));
% AllPeriodsDiffMeanDecodingAccuracyChRNL=zeros(DecodingTimes,length(AllPeriodToPlot));
% AllPeriodsDiffMeanDecodingAccuracyNpHRNL=zeros(DecodingTimes,length(AllPeriodToPlot));
% for iPeriod=1:length(AllPeriodToPlot)
%     TargetDelayPer=AllPeriodToPlot{iPeriod};
%     TargetDelayPerBinID=find(X>TargetDelayPer(1)&X<=TargetDelayPer(2));
%     TargetDelayMarker=PeriodMarkers{iPeriod};
%
%     TargetPeriodMeanDecodingAccuracy=zeros(DecodingTimes,2);
%     for isLaserGroup=1:length(CrossGroupDecodingResults)
%         %% calculate cross phased decoding accuracy
%         AllDecodingResults=CrossGroupDecodingResults{isLaserGroup};
%         MeanTargetDelayDecoding= mean(AllDecodingResults(:,TargetDelayPerBinID),2);
%         TargetPeriodMeanDecodingAccuracy(:,isLaserGroup)=MeanTargetDelayDecoding;
%     end
%     AllPeriodsDiffMeanDecodingAccuracyChRNL(:,iPeriod)=TargetPeriodMeanDecodingAccuracy(:,1)-TargetPeriodMeanDecodingAccuracy(:,2);
%     AllPeriodsDiffMeanDecodingAccuracyNpHRNL(:,iPeriod)=TargetPeriodMeanDecodingAccuracy(:,3)-TargetPeriodMeanDecodingAccuracy(:,2);
%     AllPeriodsMeanDecodingAccuracy{1,iPeriod}=TargetPeriodMeanDecodingAccuracy;
% end
% %% plot averaged Delay period decoding accuracy
% AveragedDelayDecoding=AllPeriodsMeanDecodingAccuracy{1,3};
% MeanDelayDecoding=mean(AveragedDelayDecoding(1:DecodingTimesToCompare,:));
% STD=std(AveragedDelayDecoding(1:DecodingTimesToCompare,:));
% Min=min(MeanDelayDecoding-STD);
% Max=max(MeanDelayDecoding+STD);
%
% AnovaPValue=anova1(AveragedDelayDecoding(1:DecodingTimesToCompare,:),[],'off');
%
% p=kruskalwallis(AveragedDelayDecoding(1:DecodingTimesToCompare,:),[],'off');
% [p1,~]=ranksum(AveragedDelayDecoding(1:DecodingTimesToCompare,1),AveragedDelayDecoding(1:DecodingTimesToCompare,2));
% [p2,~]=ranksum(AveragedDelayDecoding(1:DecodingTimesToCompare,3),AveragedDelayDecoding(1:DecodingTimesToCompare,2));
% BonferroniCorrection=2;
% p1=p1*2;
% p2=p2*2;
%
% errorbar(1:3,MeanDelayDecoding,STD,'-k','linewidth',1)
% hold on
%
% line([1 3],Max*1.03*[1 1],'linewidth',2,'color',[0 0 0])
% PlotPValueMarker(1.8,0.15,Max*1.04,p,[0 0 1])
% line([1 1.95],Max*1.01*[1 1],'linewidth',2,'color',[0 0 0])
% PlotPValueMarker(1.3,0.15,Max*1.02,p1,[0 0 1])
% line([2.05 3],Max*1.01*[1 1],'linewidth',2,'color',[0 0 0])
% PlotPValueMarker(2.3,0.15,Max*1.02,p2,[0 0 1])
%
% ylim([Min*0.99 min([Max*1.06 1])])
% ylabel('Decoding accuracy','fontsize',12)
% set(gca,'xtick',1:3,'xticklabel',[{'ChR2 activation'};{'NoLaser'};{'NpHR suppression'}])
% title('Averaged delay period decoding accuracy','fontsize',12)
% saveas(gcf,'Laser effects on mean delay pariod decoding accuray.fig')
% saveas(gcf,'Laser effects on mean delay pariod decoding accuray.png')
% close all
% save(['LaserEffectsOnDecoding-' TrialType DayID num2str(DecodingTimesToCompare)],'CrossGroupDecodingResults'...
%     ,'AllPeriodsDiffMeanDecodingAccuracyChRNL','AllPeriodsDiffMeanDecodingAccuracyNpHRNL'...
%     ,'AllPeriodsMeanDecodingAccuracy','TrialType','PeriodMarkers','StartTime','OdorMN','DelayMN','step_size','bin_width'...
%     ,'ResponseMN','WaterMN','ITIMN')