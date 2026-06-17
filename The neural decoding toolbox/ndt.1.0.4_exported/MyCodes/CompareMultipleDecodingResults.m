%this code was used to compare multiple decoding results
%CrossDayROCAna  AllUnitsOdorSelectivityAna PopulationHeatMap %PlotNDTDecodingResultsPermutationTest
%NDTPopulationDecoding  NDTDecodingAnaAccordingToPerformance TrialTypeAndLaserEffecsOnDecoding
%LaserEfeectsOnNDTDecodingAna TrialTypeAndLaserEffecsOnDecoding CompareTwoDecodingResultsPermTestDiff
%CompareTwoCrossDayDecoding
clear;clc;close all;
% DecodingResultsFiles=dir('*NDT*.mat');%by using the NDT decoding toolbox
DecodingResultsFiles=dir('*All Parameters*.mat');%My own decoding code
[DecodingResultsFiles,Legends,Colors,AreaColors]=SetControlTheLastFile(DecodingResultsFiles);
TitleName1='Laser effects on sample decoding';
if exist('shuffle','dir')==7
    ShuffleDecodingDir=[{'Phase1 Shuffle'};{'Phase2 Shuffle'};{'Phase3 Shuffle'}];
else
    ShuffleDecodingDir=[];
end
PlotRange=[-1 13];
% Legends=[{'Day1'};{'Day3'};{'Day5'}];%;{'Day2'};{'Day4'}
% TitleName1='Cross day decoding';
% Legends=[{'ChR'};{'NL'};{'NpHR'}];
% TitleName1='Laser effects on sample decoding';
% Legends=[{'Early'};{'Middle'};{'Late'}];
% TitleName1='Learning effects on sample decoding';
% Legends=[{'NL'};{'ChR'}];%{'DisTrials'};{'NoDisTri'}
% Legends=[{'NoLaser'};{'Laser'}];
% TitleName1='Laser effects on sample decoding';
% Legends=[{'CorrTrials'};{'ErrorTrials'}];
% TitleName1='Trial Type effects on sample decoding';
% Legends=[{'FSI neu'};{'Pyramidal neu'}];
% TitleName1='Cell Type effects on sample decoding';
% the_colors = [[0 0 0];[1 0 0]];%[[0 0 1]; [1 0 0]; [0 0.5 0]]
% Legends=[{'WithDistractor'};{'NoDistractor'}];
% TitleName1='Distractor effects on sample decoding';
% the_colors = [[0 0 1];[0 0 0];[0 0.5 0];[1 0 0]];%[[0 0 1]; [1 0 0]; [0 0.5 0]]
DayID=[];
DayMarker=regexpi(DecodingResultsFiles{1},'-Day');
if ~isempty(DayMarker)
    DayID=DecodingResultsFiles{1}(DayMarker:DayMarker+5);
end
% StartTime=0;
AllPhases=[1 2];%define the learning phase to be calculated [1 2 3]
IsClusterBasedPermationTest=1;
ShuffleDecodingTimes=1000;
PlotDecodingPerCorr=0;
if isequal(TitleName1,'Cross day decoding')
    Colors=[[0 0 1];[0 0.5 0];[0 0 0];[1 0 0];[0.6 0 0];[0.4 0 0];[0.2 0 0]];
end
TimeGain=10;
if size(DecodingResultsFiles,1)>0
    FileName=DecodingResultsFiles{1};
    if isempty(DayID)
        Group='-NL';
        IsChR=regexpi(FileName,'ChR');
        if ~isempty(IsChR)
            Group='-ChR';
        end
        NpHR=regexpi(FileName,'NpHR');
        if ~isempty(NpHR)
            Group='-NpHR';
        end
    else
        Group=DayID;
    end
    Path=pwd;
    OdorID=regexpi(FileName,'Odor');
    MCCID=regexpi(FileName,'-MCC');
    DecodingParameters=FileName(OdorID+4:MCCID-1);
    h=zeros(1,size(DecodingResultsFiles,1));
    YMax=zeros(1,size(DecodingResultsFiles,1));
    YMin=zeros(1,size(DecodingResultsFiles,1));
    AllDecodingResults=cell(3,size(DecodingResultsFiles,1));
    CrossphasesPermutationTestIsSignificant=cell(2,size(DecodingResultsFiles,1));
    for iResult=1:size(DecodingResultsFiles,1)
        load(DecodingResultsFiles{iResult})
        
        if isstruct(DECODING_RESULTS)
            DecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;
            MeanDecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results';
            curr_stdev_to_plot =DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples';
        else
            DecodingResults=DECODING_RESULTS;
            MeanDecodingResults=mean(DECODING_RESULTS);
            curr_stdev_to_plot =std(DECODING_RESULTS);
        end
        
        AllDecodingResults{1,iResult}=DecodingResults;
        AllDecodingResults{2,iResult}=MeanDecodingResults;
        AllDecodingResults{3,iResult}=curr_stdev_to_plot;
        
        ProceedingBinNum=bin_width/step_size;
        TimeBinNumber=length(MeanDecodingResults);
        X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
        X=X+ProceedingBinNum*step_size/1000;
        if iResult==1
            AddLegend(Legends,Colors,'northeast')
        end
        hold on
        
        %curr_stdev_to_plot=zeros(size(curr_stdev_to_plot));        
        [y2,y1]=PlotMeanSEM(MeanDecodingResults,X,[Colors(iResult,:);Colors(iResult,:)],PlotRange,'-',1,curr_stdev_to_plot);
        %% cluster-based permutation test        
        if exist('TimeLampsedIsSignificant','var')&&~isempty(TimeLampsedIsSignificant)            
            for iBin = 1:length(TimeLampsedIsSignificant)
                if TimeLampsedIsSignificant(iBin)==1
                    plot(X(iBin),0.33+iResult*0.02,'.','color',Colors(iResult,:),'markersize',3)
                end
            end
            CrossphasesPermutationTestIsSignificant{1,iResult}=TimeLampsedIsSignificant;
        end
        YMax(iResult)=max(y1);
        YMin(iResult)=min(y2);
    end     
%        plot([4 4], get(gca, 'YLim'),'--','color',[1 0 1],'linewidth',1)
%         plot([4+1 4+1], get(gca, 'YLim'),'--','color',[1 0 1],'linewidth',1)
     %4-ProceedingBinNum*step_size/1000+0.05
    text(2.0,0.95,['NeuronNum=' num2str(num_neuron_ForDecoding)])
    plot([-(4-StartTime) 2*OdorMN+DelayMN+ResponseMN+WaterMN+ITIMN-4],[0.5 0.5],'k','linewidth',2)
    EventCurve(OdorMN,DelayMN,ResponseMN,WaterMN,max(YMax),0.42);
    xlabel('Time from sample onset(s)','fontsize',12)
    ylabel('Decoding Accuracy','fontsize',12)
    set(gca,'fontsize',12,'TickDir','out')
    axis([PlotRange 0.3 min([max(YMax)*1.1 1])])
    box off
    title([TitleName1 DecodingParameters Group],'fontsize',12)
    saveas(gcf,[TitleName1 DecodingParameters Group],'fig')%
    saveas(gcf,[TitleName1 DecodingParameters Group],'png')%
    close all
    %% compare delay period decoding power
    Delay12=((4-StartTime)+OdorMN)*TimeGain+1:((4-StartTime)+OdorMN+2)*TimeGain;
    Delay45=((4-StartTime)+OdorMN+3)*TimeGain+1:((4-StartTime)+OdorMN+DelayMN)*TimeGain;
    DelayPer=((4-StartTime)+OdorMN)*TimeGain+1:((4-StartTime)+OdorMN+DelayMN)*TimeGain;
    
    CrossPhaseDecoding=AllDecodingResults(1,:);
    if length(size(CrossPhaseDecoding{1}))==3
        CVAveragedCrossPhaseDecoding=cellfun(@(x) mean(x,2),CrossPhaseDecoding,'uniformoutput',0);
        ResampleRun=size(CVAveragedCrossPhaseDecoding{1},1);
        BinNum=size(CVAveragedCrossPhaseDecoding{1},3);
        CrossPhaseResampleDecoding=cellfun(@(x) reshape(x,ResampleRun,BinNum),CVAveragedCrossPhaseDecoding,'uniformoutput',0);
    else
        CrossPhaseResampleDecoding=CrossPhaseDecoding;
    end
    MeanCrossPhaseCrossResampleDelayDecoding=cellfun(@(x) mean(x(:,DelayPer),2),CrossPhaseResampleDecoding,'uniformoutput',0);
    AveragedCrossPhaseDelayDecoding=cellfun(@mean,MeanCrossPhaseCrossResampleDelayDecoding,'uniformoutput',1);
    CrossPhaseCrossResampleStd=cellfun(@std,MeanCrossPhaseCrossResampleDelayDecoding,'uniformoutput',1);
    Min=min(AveragedCrossPhaseDelayDecoding-CrossPhaseCrossResampleStd);
    Max=max(vertcat(MeanCrossPhaseCrossResampleDelayDecoding{:}));
    
%     if exist('PhasesNeuronID','var')
%         CrossPhasePerformance=PhasesNeuronID(2,:);
%         AveragedCrossPhasePer=cellfun(@mean,CrossPhasePerformance);
%     else
%         CrossPhasePerformance=NeuronIndexInEachTrainingDay(2,1:size(DecodingResultsFiles,1));
%         AveragedCrossPhasePer=cellfun(@mean,CrossPhasePerformance);
%     end
    if PlotDecodingPerCorr==1        
%         plot(AveragedCrossPhasePer(AllPhases),AveragedCrossPhaseDelayDecoding,'k*-','linewidth',2)
%         hold on
        %errorbar(AveragedCrossPhasePer(AllPhases),AveragedCrossPhaseDelayDecoding,CrossPhaseCrossResampleStd,'k-','linewidth',2)
        
        bar(AveragedCrossPhasePer,AveragedCrossPhaseDelayDecoding,'facecolor','none','edgecolor',[0 0 1])%(AllPhases)
        hold on
        %errorbar(AveragedCrossPhasePer(AllPhases),AveragedCrossPhaseDelayDecoding,CrossPhaseCrossResampleStd,'LineStyle','none','linewidth',1)%
        for i=1:length(AllPhases)%plot the 95th confidence interval
            tempPer=AveragedCrossPhasePer(i);%AllPhases(i)
            AllMeanDelayDecodingAccuracy=MeanCrossPhaseCrossResampleDelayDecoding{i};
            The975Percentile=prctile(AllMeanDelayDecodingAccuracy,97.5);
            The25Percentile=prctile(AllMeanDelayDecodingAccuracy,2.5);
            
            plot([tempPer tempPer],[The25Percentile The975Percentile],'-k')
        end
        for iPhase=1:length(AllPhases)
            X=(AveragedCrossPhasePer(AllPhases(iPhase))+3)*ones(1,length(MeanCrossPhaseCrossResampleDelayDecoding{iPhase}));
            plot(X,MeanCrossPhaseCrossResampleDelayDecoding{iPhase},'o','markersize',10)
        end
        [p1,~]=ranksum(MeanCrossPhaseCrossResampleDelayDecoding{1},MeanCrossPhaseCrossResampleDelayDecoding{2});
        line(AveragedCrossPhasePer(AllPhases),[Max*1.02 Max*1.02],'linewidth',2)
        PlotPValueMarker(mean(AveragedCrossPhasePer(AllPhases)),2,Max*1.03,p1,[0 0 0])  
        
        ylim([Min*0.95 min([Max*1.05 1])])
        xlabel('Learning phase','fontsize',12)
        ylabel('Decoding accuracy','fontsize',12)
        set(gca,'xtick',ceil(AveragedCrossPhasePer(AllPhases)),'xticklabel',Legends)
        title(['Learning effects on delay sample decoding' Group],'fontsize',14)
        saveas(gcf,[TitleName1 DecodingParameters Group '-Decoding-Per corr'],'fig')%
        saveas(gcf,[TitleName1 DecodingParameters Group '-Decoding-Per corr'],'png')%
        close all
    end
end
save([TitleName1 Group],'AllDecodingResults','OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','TimeGain','bin_width','step_size'...
    ,'AveragedCrossPhaseDelayDecoding','CrossPhaseCrossResampleStd','MeanCrossPhaseCrossResampleDelayDecoding'...
    ,'CrossphasesPermutationTestIsSignificant','StartTime')%,'AveragedCrossPhasePer','CrossPhasePerformance'
