%Compare the difference of decoding accuracy between laer and no-Laser
%conditions with different trial types used 
%CompareMultipleDecodingResults LaserEfeectsOnNDTDecodingAna 
clear;clc;close all;
LaserEffectOnDecodingFiles=dir('*LaserEffectsOnDecoding*.mat');
Legends=[{'All Trials'};{'Correct Trials'};{'Error Trials'}];
Colors=[[0 0 0];[0 0 1];[1 0 0]];

DecodingTimesToCompare=20;

load(LaserEffectOnDecodingFiles(1).name)
DecodingTimes=size(AllPeriodsDiffMeanDecodingAccuracyChRNL,1);
AllTrialTypesDiffDelay12Decoding=zeros(DecodingTimes,size(LaserEffectOnDecodingFiles,1));
AllTrialTypesDiffDelay45Decoding=zeros(DecodingTimes,size(LaserEffectOnDecodingFiles,1));
AllTrialTypesDiffWholeDelayDecoding=zeros(DecodingTimes,size(LaserEffectOnDecodingFiles,1));
AllTrialTypesDiffDelay12Decoding1=zeros(DecodingTimes,size(LaserEffectOnDecodingFiles,1));
AllTrialTypesDiffDelay45Decoding1=zeros(DecodingTimes,size(LaserEffectOnDecodingFiles,1));
AllTrialTypesDiffWholeDelayDecoding1=zeros(DecodingTimes,size(LaserEffectOnDecodingFiles,1));
for iResult=1:size(LaserEffectOnDecodingFiles,1)
    load(LaserEffectOnDecodingFiles(iResult).name)
    
    AllTrialTypesDiffDelay12Decoding(:,iResult)=AllPeriodsDiffMeanDecodingAccuracyNpHRNL(:,1);
    AllTrialTypesDiffDelay45Decoding(:,iResult)=AllPeriodsDiffMeanDecodingAccuracyNpHRNL(:,2);
    AllTrialTypesDiffWholeDelayDecoding(:,iResult)=AllPeriodsDiffMeanDecodingAccuracyNpHRNL(:,3);
    
    AllTrialTypesDiffDelay12Decoding1(:,iResult)=AllPeriodsDiffMeanDecodingAccuracyChRNL(:,1);
    AllTrialTypesDiffDelay45Decoding1(:,iResult)=AllPeriodsDiffMeanDecodingAccuracyChRNL(:,2);
    AllTrialTypesDiffWholeDelayDecoding1(:,iResult)=AllPeriodsDiffMeanDecodingAccuracyChRNL(:,3);
end
NpHRNLDiffDecodingAccuracy=[{AllTrialTypesDiffDelay12Decoding} {AllTrialTypesDiffDelay45Decoding} {AllTrialTypesDiffWholeDelayDecoding}];
ChRNLDiffDecodingAccuracy=[{AllTrialTypesDiffDelay12Decoding1} {AllTrialTypesDiffDelay45Decoding1} {AllTrialTypesDiffWholeDelayDecoding1}];
TwoGroupDiff=[{ChRNLDiffDecodingAccuracy} {NpHRNLDiffDecodingAccuracy}];
%%
GroupID=[{'ChR2-No laser'};{'NpHR-No laser'}];
for iGroup=1:2
    AllPeriodsDiffDecodingAccuracy=TwoGroupDiff{iGroup};
    tempGroupID=GroupID{iGroup};
    for iPeriod=3%1:length(AllPeriodsDiffDecodingAccuracyNpHRNL)
        TargetDelayMarker=PeriodMarkers{iPeriod};
        TargetDiffMeanDecodingAccuracy=AllPeriodsDiffDecodingAccuracy{iPeriod};
        TargetDiffMeanDecodingAccuracy=TargetDiffMeanDecodingAccuracy(1:DecodingTimesToCompare,:)*100;
        
        Mean=mean(TargetDiffMeanDecodingAccuracy);
        STD=std(TargetDiffMeanDecodingAccuracy);
        Max=max(Mean+STD);
        Min=min(Mean-STD);
        
        bar(1:3,Mean,'facecolor','none','edgecolor',[0 0 1])
        hold on
        errorbar(1:3,Mean,STD,'LineStyle','none','linewidth',2)%,'linestype','none'
        
        for iTrialType=1:size(TargetDiffMeanDecodingAccuracy,2)
            plot(iTrialType*ones(size(TargetDiffMeanDecodingAccuracy,1),1)-0.1,TargetDiffMeanDecodingAccuracy(:,iTrialType),'o','markersize',10)
        end
        %do rank sumation test All trials vs correct trial
        [p1,~]=ranksum(TargetDiffMeanDecodingAccuracy(:,1),TargetDiffMeanDecodingAccuracy(:,2));
        line([1 1.9],[Max*1.25 Max*1.25],'linewidth',2)
        if p1<0.001
            plot(1.3,Max*1.29,'*','Markersize',10)
            plot(1.5,Max*1.29,'*','Markersize',10)
            plot(1.7,Max*1.29,'*','Markersize',10)
        elseif p1>0.05
            text(1.3,Max*1.29,'n.s.')
        end
        %do rank sumation test Correct trials vs error trial
        [p2,~]=ranksum(TargetDiffMeanDecodingAccuracy(:,2),TargetDiffMeanDecodingAccuracy(:,3));
        if p2<0.001
            line([2.1 3],[Max*1.25 Max*1.25],'linewidth',2)
            plot(2.3,Max*1.296,'*','Markersize',10)
            plot(2.5,Max*1.29,'*','Markersize',10)
            plot(2.7,Max*1.29,'*','Markersize',10)
        end
        %do rank sumation test All trials vs error trial
        [p3,~]=ranksum(TargetDiffMeanDecodingAccuracy(:,1),TargetDiffMeanDecodingAccuracy(:,3));
        if p3<0.001
            line([1 3],[Max*1.33 Max*1.33],'linewidth',2)
            plot(1.8,Max*1.37,'*','Markersize',10)
            plot(2.0,Max*1.37,'*','Markersize',10)
            plot(2.2,Max*1.37,'*','Markersize',10)
        end
        text(2.6,Max*0.85,['DecodingTimes=' num2str(DecodingTimesToCompare)])
        set(gca,'xtick',1:3,'xticklabel',[{'All Trials'};{'Correct Trials'};{'Error Trials'}])
        ylabel('Diff mean decoding accuracy','fontsize',12)
        axis([0.5 3.5 Min-1 Max*1.5])
        title([tempGroupID '-' TargetDelayMarker],'fontsize',16)
        saveas(gcf,[tempGroupID '-Trial type and laser effects on decoding-' TargetDelayMarker '-' num2str(DecodingTimesToCompare)],'fig')%
        saveas(gcf,[tempGroupID '-Trial type and laser effects on decoding-' TargetDelayMarker '-' num2str(DecodingTimesToCompare)],'png')%
        close all
    end
end