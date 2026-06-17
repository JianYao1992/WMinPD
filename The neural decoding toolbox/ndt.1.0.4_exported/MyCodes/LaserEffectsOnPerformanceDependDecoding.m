%this code was used to compare the learning effects on decoding between
%laser and no-laser condition
clear;clc;close all
DecodingResultsFiles=dir('*Learning effects on sample decoding*.mat');
PhaseID=[{'Early'};{'Middle'};{'Late'}];

DecodingTimesToCompare=50;
% Colors = [[0 0 1];[0 0 0]; [0 0.5 0]];
Colors = [[0 0 1];[0 0 0];[0 0.5 0]];
%% bar plot of the decoding results in the last second
MaxPerformance=zeros(1,size(DecodingResultsFiles,1));
MinPermance=zeros(1,size(DecodingResultsFiles,1));
AllAveragedCrossPhasePer=zeros(size(DecodingResultsFiles,1),3);
AllPerLeft=zeros(size(DecodingResultsFiles,1),3);
AllPerRight=zeros(size(DecodingResultsFiles,1),3);
LaserAndNLCrossPhasedDecodingResults=cell(1,size(DecodingResultsFiles,1));
for iResult=1:size(DecodingResultsFiles,1)
    load(DecodingResultsFiles(iResult).name)
    
    LaserAndNLCrossPhasedDecodingResults{iResult}=AllDecodingResults;
    %% calculate cross phased performance
    AllAveragedCrossPhasePer(iResult,:)=cellfun(@mean,CrossPhasePerformance);
    CrossPhsseStd=cellfun(@std,CrossPhasePerformance);
    AllPerLeft(iResult,:)=AveragedCrossPhasePer-CrossPhsseStd;
    AllPerRight(iResult,:)=AveragedCrossPhasePer+CrossPhsseStd;
    MaxPerformance(1,iResult)=max(AllPerRight(iResult,:));
    MinPermance(1,iResult)=min(AllPerLeft(iResult,:));
end
%% define the event period to calculate the maen decoding accuracy
Delay12=[OdorMN OdorMN+2];
Delay45=[OdorMN+3 OdorMN+DelayMN];
WholeDelayPer=[OdorMN OdorMN+DelayMN];
AllPeriodToPlot=[{Delay12};{Delay45};{WholeDelayPer}];

% StartTime=2;
TimeBinNumber=length(AllDecodingResults{2,1});
X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
ProceedingBinNum=bin_width/step_size;
X=X+ProceedingBinNum*step_size/1000;
%%
PeriodMarkers=[{'Delay12'};{'Delay45'};{'WholeDelay'}];
for iPeriod=1:length(AllPeriodToPlot)
    TargetDelayPer=AllPeriodToPlot{iPeriod};
    TargetDelayPerBinID=find(X>=TargetDelayPer(1)&X<TargetDelayPer(2));
    TargetDelayMarker=PeriodMarkers{iPeriod};
    
    MaxDecoding=zeros(1,size(DecodingResultsFiles,1));
    MinDecoding=zeros(1,size(DecodingResultsFiles,1));
    AnovaCrossPhaseDecoding=zeros(50*3,size(DecodingResultsFiles,1));
    figure
    for iResult=1:size(DecodingResultsFiles,1)
        %% calculate cross phased decoding accuracy
        AllDecodingResults=LaserAndNLCrossPhasedDecodingResults{iResult};
        CrossPhaseDecoding=AllDecodingResults(1,:);
        if length(size(CrossPhaseDecoding{1}))==3
            CVAveragedCrossPhaseDecoding=cellfun(@(x) mean(x,2),CrossPhaseDecoding,'uniformoutput',0);
            ResampleRun=size(CVAveragedCrossPhaseDecoding{1},1);
            BinNum=size(CVAveragedCrossPhaseDecoding{1},3);
            CrossPhaseResampleDecoding=cellfun(@(x) reshape(x,ResampleRun,BinNum),CVAveragedCrossPhaseDecoding,'uniformoutput',0);
        else
            CrossPhaseResampleDecoding=CrossPhaseDecoding;
        end
        MeanCrossPhaseCrossResampleDelayDecoding=cellfun(@(x) mean(x(:,TargetDelayPerBinID),2),CrossPhaseResampleDecoding,'uniformoutput',0);
        
        AveragedCrossPhaseDelayDecoding=cellfun(@(x) mean(x(1:DecodingTimesToCompare)),MeanCrossPhaseCrossResampleDelayDecoding,'uniformoutput',1);
        CrossPhaseCrossResampleStd=cellfun(@(x) std(x(1:DecodingTimesToCompare)),MeanCrossPhaseCrossResampleDelayDecoding,'uniformoutput',1);
        
        DecodingUp=AveragedCrossPhaseDelayDecoding+CrossPhaseCrossResampleStd;
        DecodingDown=AveragedCrossPhaseDelayDecoding-CrossPhaseCrossResampleStd;
        
        MaxDecoding(1,iResult)=max(DecodingUp);
        MinDecoding(1,iResult)=min(DecodingDown);
        
        AnovaTargetDelayDecodingResults=vertcat(MeanCrossPhaseCrossResampleDelayDecoding{:});
        AnovaCrossPhaseDecoding(:,iResult)=AnovaTargetDelayDecodingResults;
        
        AveragedCrossPhasePer=AllAveragedCrossPhasePer(iResult,:);
        PerLeft=AllPerLeft(iResult,:);
        PerRight=AllPerRight(iResult,:);
        %%
        AddLegend([{'ChR2'};{'No Laser'};{'NpHR'}],[[0 0 1];[0 0 0];[0 0.5 0]],'northwest');
        hold on
        plot(AveragedCrossPhasePer,AveragedCrossPhaseDelayDecoding,'*-','color',Colors(iResult,:),'linewidth',2)
        %% add performance errorbar
        for iPhase=1:3
            line([PerLeft(iPhase) PerRight(iPhase)],AveragedCrossPhaseDelayDecoding(iPhase)*[1 1],'color',Colors(iResult,:),'linewidth',2)
            if iResult==1
                text(AveragedCrossPhasePer(iPhase)*0.9,DecodingDown(iPhase)*0.98,PhaseID{iPhase},'color',Colors(iResult,:))
            elseif iResult==2
                text(AveragedCrossPhasePer(iPhase)*0.93,DecodingUp(iPhase)*1.02,PhaseID{iPhase},'color',Colors(iResult,:))
            end
        end
        %% add decoding errorbar
        errorbar(AveragedCrossPhasePer,AveragedCrossPhaseDelayDecoding,CrossPhaseCrossResampleStd,'color',Colors(iResult,:),'linewidth',2)
        %% anova2 test
        if iResult==3
            [AnovaPalue,table]=anova2(AnovaCrossPhaseDecoding,3,'off');% 3 stand for 3 phases
            if AnovaPalue(1)<0.001
                plot([max(MaxPerformance)*1.01 max(MaxPerformance)*1.01],[min(MinDecoding) max(MaxDecoding)],'-k','linewidth',2)
                plot(max(MaxPerformance)*1.03,max(MaxDecoding)*0.98,'*','markersize',10)
                plot(max(MaxPerformance)*1.03,max(MaxDecoding)*0.92,'*','markersize',10)
                plot(max(MaxPerformance)*1.03,max(MaxDecoding)*0.86,'*','markersize',10)
            end
            text(60,85,['DecodingTime=' num2str(DecodingTimesToCompare)])
            axis([min([50 min(MinPermance)*0.9]) min([100 max(MaxPerformance)*1.05]) min(MinDecoding)*0.98 min([1 max(MaxDecoding)*1.02])])
            xlabel('Performance','fontsize',12)
            ylabel('Decoding accuracy','fontsize',12)
            title(['Decoding accuracy-performance correlation-' TargetDelayMarker '-' num2str(DecodingTimesToCompare)],'fontsize',14)
            saveas(gcf,['Laser effects on decoding-Per correlation-' TargetDelayMarker '-' num2str(DecodingTimesToCompare)],'fig')%
            saveas(gcf,['Laser effects on decoding-Per correlation-' TargetDelayMarker '-' num2str(DecodingTimesToCompare)],'png')%
            close all
        end
    end
end