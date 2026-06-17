%this code was used to compare the learning effects on decoding between
%laser and no-laser condition
clear;clc;close all
DecodingResultsFiles=dir('*Learning effects on sample decoding*.mat');
LaserGroup=dir('*NpHR*.mat');
DecodingResultsFiles=ReAlignDecodingFileName(LaserGroup,DecodingResultsFiles);
PhaseID=[{'Learning early'};{'Learning middle'};{'Learning late'}];

Colors = [[0 0 0]; [0 0.5 0]];
%% bar plot of the decoding results in the last second
MaxPerformance=zeros(1,2);
MinPermance=zeros(1,2);
AllAveragedCrossPhasePer=zeros(2,3);
AllPerLeft=zeros(2,3);
AllPerRight=zeros(2,3);
LaserAndNLCrossPhasedDecodingResults=cell(1,2);
for iResult=1:size(DecodingResultsFiles,1)
    load(DecodingResultsFiles{iResult})
    
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

StartTime=2;
TimeBinNumber=length(AllDecodingResults{2,1});
X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-2)-step_size/1000;
ProceedingBinNum=bin_width/step_size;
X=X+ProceedingBinNum*step_size/1000;
%%
PeriodMarkers=[{'Delay12'};{'Delay45'};{'WholeDelay'}];
for iPeriod=1:length(AllPeriodToPlot)
    TargetDelayPer=AllPeriodToPlot{iPeriod};
    TargetDelayPerBinID=find(X>TargetDelayPer(1)&X<=TargetDelayPer(2));
    TargetDelayMarker=PeriodMarkers{iPeriod};
    
    MaxDecoding=zeros(1,2);
    MinDecoding=zeros(1,2);
    AnovaCrossPhaseDecoding=zeros(50*3,2);
    figure
    for iResult=1:size(DecodingResultsFiles,1)
        %% calculate cross phased decoding accuracy
        AllDecodingResults=LaserAndNLCrossPhasedDecodingResults{iResult};
        CrossPhaseDecoding=AllDecodingResults(1,:);
        CVAveragedCrossPhaseDecoding=cellfun(@(x) mean(x,2),CrossPhaseDecoding,'uniformoutput',0);
        ResampleRun=size(CVAveragedCrossPhaseDecoding{1},1);
        BinNum=size(CVAveragedCrossPhaseDecoding{1},3);
        CrossPhaseResampleDecoding=cellfun(@(x) reshape(x,ResampleRun,BinNum),CVAveragedCrossPhaseDecoding,'uniformoutput',0);
        MeanCrossPhaseCrossResampleDelayDecoding=cellfun(@(x) mean(x(:,TargetDelayPerBinID),2),CrossPhaseResampleDecoding,'uniformoutput',0);
        AveragedCrossPhaseDelayDecoding=cellfun(@mean,MeanCrossPhaseCrossResampleDelayDecoding,'uniformoutput',1);
        CrossPhaseCrossResampleStd=cellfun(@std,MeanCrossPhaseCrossResampleDelayDecoding,'uniformoutput',1);
        
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
        AddLegend([{'No Laser'};{'Laser'}],[[0 0 0];[0 0.5 0]],'northwest');
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
        if iResult==2
            [AnovaPalue,table]=anova2(AnovaCrossPhaseDecoding,3,'off');% 3 stand for 3 phases
            if AnovaPalue(1)<0.001
                plot([max(MaxPerformance)*1.01 max(MaxPerformance)*1.01],[min(MinDecoding) max(MaxDecoding)],'-k','linewidth',2)
                plot(max(MaxPerformance)*1.03,max(MaxDecoding)*0.98,'*','markersize',10)
                plot(max(MaxPerformance)*1.03,max(MaxDecoding)*0.92,'*','markersize',10)
                plot(max(MaxPerformance)*1.03,max(MaxDecoding)*0.86,'*','markersize',10)
            end            
            axis([min([50 min(MinPermance)*0.9]) min([100 max(MaxPerformance)*1.05]) min(MinDecoding)*0.95 min([1 max(MaxDecoding)*1.05])])
            xlabel('Performance','fontsize',12)
            ylabel('Decoding accuracy','fontsize',12)
            title(['Decoding accuracy-performance correlation-' TargetDelayMarker],'fontsize',14)
            saveas(gcf,['Laser effects on decoding-Per correlation-' TargetDelayMarker],'fig')%
            saveas(gcf,['Laser effects on decoding-Per correlation-' TargetDelayMarker],'png')%
            close all
        end
    end
end