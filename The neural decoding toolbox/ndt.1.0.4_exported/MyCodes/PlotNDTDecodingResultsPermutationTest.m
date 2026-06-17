%this code was used to plot NDT decoding results
%CompareMultipleDecodingResults  PlotTCTDecodingPermutationTest PlotTCTTargetBin
%CrossDayROCAna  AllUnitsOdorSelectivityAna PopulationHeatMap NDTPopulationDecoding
%LaserEfeectsOnNDTDecodingAna  CompareDiffDecoding PlotCQDecodingResults
% addpath(genpath('D:\CQ\Matlab codes'))
clear;clc;close all;
IsClusterBasedPermationTest=1;%0 for permutation test without cluster correction
ShuffleDecodingTimes=1000;
DecodingTimes=50;

IsCorrectOrErrorOrAllTrials=3;
CurrentPath=pwd;
AllPath=genpath(CurrentPath);
SplitPath=strsplit(AllPath,';');
SubPath=SplitPath';
SubPath=SubPath(1:end-1);
SubPath=ExcludeShuffleDir(SubPath);
for iPath=1:size(SubPath,1)%go through each directory
    Path=SubPath{iPath,1};
    cd(Path);
    
    if exist('shuffle','dir')==7
        ShuffleDecodingDir='Shuffle';
    else
        ShuffleDecodingDir=[];
    end
    Path=pwd;
    PermutationDecodingResultsDir=[Path '\' ShuffleDecodingDir '\'];
    AllParametersDecodingFile=dir('*Parameters.mat*');
    AllDecodingFile=dir('*NDT*.mat');%Parameters.mat
%     AllDecodingFile=dir('*Decoding*.mat');%Parameters.mat       
    
    if IsClusterBasedPermationTest==1
        PostFix='-ClusterBasedPermutationTest';
    else
        PostFix='-PermutationTest';
    end
    the_colors = [[0 0 1]; [1 0 0]; [0 0.5 0]];
    if size(AllParametersDecodingFile,1)>0
        load(AllParametersDecodingFile.name)   
        StartTime=0;        
        
        if iscell(DECODING_RESULTS)
            DECODING_RESULTS=DECODING_RESULTS{1};
        end
        DayIndex=regexpi(AllParametersDecodingFile.name,'Day');
        AllParaIndex=regexpi(AllParametersDecodingFile.name,'-All Parameters');
        DayID=AllParametersDecodingFile.name(DayIndex-1:AllParaIndex-5);
        
        if ~exist('TitleName','var')
            ID=regexpi(AllParametersDecodingFile.name,'-All Parameters');
            TitleName=AllParametersDecodingFile.name(1:ID-1);
        end
        if exist('DECODING_RESULTS','var')&&isstruct(DECODING_RESULTS)
            RealDecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
            TimeBinNumber=size(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results,1);
            curr_stdev_to_plot =DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples;
        else
            DecodingResults=DECODING_RESULTS;
            MeanDecodingResults=mean(DECODING_RESULTS);
            curr_stdev_to_plot =std(DECODING_RESULTS);
        end
        if size(AllDecodingFile,1)>5%construct real decoding from multiple files
            [RealCrossReSampleDecodingResults,RealDecodingResults,curr_stdev_to_plot,TimeBinNumber]...
                =ConstruceNDTRealDecodingResults(AllDecodingFile,DecodingTimes);
            DECODING_RESULTS=RealCrossReSampleDecodingResults;
        end        
        %     if StartTime==0
        %         RealDecodingResults(1:40)=[];
        %         curr_stdev_to_plot(1:40)=[];
        %         TimeBinNumber=TimeBinNumber-40;
        %     end
        ProceedingBinNum=bin_width/step_size-1;
        X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
        X=X+ProceedingBinNum*step_size/1000;
        X=X+step_size/1000/2;
        
        AddLegend({'Sample Decoding'},[the_colors(1,:);[0 0 0]],'northeast');
        hold on
        [YMin,YMax]=PlotMeanSEM(RealDecodingResults,X,[the_colors(1,:)*0.8;the_colors(1,:)],[-2 OdorMN*2+DelayMN+ResponseMN+6],'-',1,curr_stdev_to_plot');
        EventCurve(OdorMN,DelayMN,ResponseMN,WaterMN,YMax,YMin);
        
        text(3.5,0.85,['NeuronNum=' num2str(num_neuron_ForDecoding)],'fontsize',12,'color',[0 0 1])
        %% cluster-based permutation test
        TimeLampsedIsSignificant=[];
        if ~isempty(ShuffleDecodingDir)
            null_distributions=CQ_create_nulldist_from_shuffle_files(PermutationDecodingResultsDir,ShuffleDecodingTimes);
            TimeLampsedIsSignificant=ClusterBasedPermutationTest(RealDecodingResults,null_distributions(1:ShuffleDecodingTimes,:)...
                ,IsClusterBasedPermationTest,ShuffleDecodingTimes);
            NinetyFiveCI=zeros(2,size(null_distributions,2));
            for i=1:size(null_distributions,2)
               NinetyFiveCI(:,i)=[prctile(null_distributions(:,i),97.5);prctile(null_distributions(:,i),2.5)];                
            end
            PlotMeanSEM(null_distributions,X,[[0.4 1 0.4];[0 0.5 0]],NinetyFiveCI);
        end        
        plot([-2 2*OdorMN+DelayMN+ResponseMN+WaterMN+ITIMN-4],[0.5 0.5],'k','linewidth',2)
%         for iBin = 1:length(TimeLampsedIsSignificant)
%             if TimeLampsedIsSignificant(iBin)==1
%                 plot(X(iBin),0.35,'b.','markersize',5)
%             end
%         end
         plot(X(TimeLampsedIsSignificant==1),0.35*ones(1,sum(TimeLampsedIsSignificant)),'b.','markersize',5)
         if ~isempty(regexpi(TitleName,'DisTrials'))&&isempty(regexpi(TitleName,'NoDisTrials'))
            plot([4-ProceedingBinNum*step_size/1000+0.05 4-ProceedingBinNum*step_size/1000+0.05], get(gca, 'YLim'),'--','color',[1 0 1],'linewidth',1.5)
            plot([4-ProceedingBinNum*step_size/1000+0.05+1 4-ProceedingBinNum*step_size/1000+0.05+1], get(gca, 'YLim'),'--','color',[1 0 1],'linewidth',1.5)
         end
        xlabel('Time from sample onset(s)','fontsize',12)
        ylabel('Decoding Accuracy','fontsize',12)
        set(gca,'fontsize',12,'TickDir','out')
        axis([-(4-StartTime) 2*OdorMN+DelayMN+ResponseMN+WaterMN+ITIMN-4 0.3 min([YMax*1.1 1])])
        box off
        title([TitleName DayID PostFix])
        cd(SubPath{1})
        saveas(gcf,[TitleName DayID PostFix],'fig')%
        saveas(gcf,[TitleName DayID PostFix] ,'png')%
        %ResizeFigureForPaper([TitleName DayID PostFix],[1.51 1.15],[-0.5 7.2 0.3 1],0,[-2 0 2 4 6 8],[0.4 0.6 0.8 1])
        close all
        if ~exist('IsSustainedOdorSelectiveNeuron','var')
           IsSustainedOdorSelectiveNeuron=6;            
        end
%         if ~exist('TargetNeuronIDWithSpecificSigBin','var')
%            TargetNeuronIDWithSpecificSigBin=1:length(binned_data); 
%            AddSustainedNeuronWithSigBinNum=6;
%         end
        if size(AllDecodingFile,1)>5%construct real decoding from multiple files
            save([TitleName DayID '-All Parameters-1'],'DECODING_RESULTS','TimeLampsedIsSignificant','X'...
                ,'DecodingForSamTestDecisionTrialType','IsShffleDecoding','num_resample_runs','num_cv_splits','TitleName'...
                ,'num_neuron_ForDecoding','TitleName','Classifier','bin_width','step_size'...
                ,'OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','IsCorrectOrErrorOrAllTrials'...
                ,'StartTime','IsSustainedOdorSelectiveNeuron','IsCorrectOrErrorOrAllTrials'...
                ,'TargetNeuronIDWithSpecificSigBin','AddSustainedNeuronWithSigBinNum','-v7.3');%,'PoolSize','IsExcludeNLNeurons'
        end        
%         if exist('TimeLampsedIsSignificant','var')
%            save([TitleName DayID 'All Parameters-1'],'TimeLampsedIsSignificant','-append') 
%         end
%         if exist('NeuronIndexInEachTrainingDay','var')
%            save([TitleName DayID 'All Parameters-1'],'NeuronIndexInEachTrainingDay','-append') 
%         end
%         if exist('PhasesNeuronID','var')
%            save([TitleName DayID 'All Parameters-1'],'PhasesNeuronID','-append') 
%         end
    end
end
cd(SubPath{1})