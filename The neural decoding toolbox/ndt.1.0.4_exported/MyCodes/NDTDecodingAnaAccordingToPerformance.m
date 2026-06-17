%the code was used to calculate the decoding efficiency with the Neural
%Decoding Toolbox according to the performance
%PerDependentROCAna NDTDecodingAnaAccordingToPerformance %CQDecodingOld
%CrossDayROCAna  AllUnitsOdorSelectivityAna PopulationHeatMap NDTPopulationDecoding
clear;clc;close all;
TargetBrainID='AI';%define the brain area for summary
PlotSingleDayPerformance=0;
IsShffleDecoding=0;
Decodingclassifier=1;%1 for max_correlation_coefficient_CL£¬2 for poisson_naive_bayes_CL£¬3 for support vector machine
DecodingForSamTestDecisionTrialType=1;% Decoding for 1-sample odor,2-test odor, 3-decision(FC or CR in nonpair trials), 4-trial type(Pair-Nonpair)
ShuffleDecodingDir=[];%'ShuffleDecoding-AI-for Sample Odor-10-10-150-470-MCC';%define the directory of shuffle decoding results files
IsCalculateTCTDecodingResults=0;
AllPhases=[1 2 3];%define the learning phase to be calculated [1 2 3]
%PhaseCriterion=[60 60 79 79]: NL [224 236 244]; ChR2:[226 178 198]; NpHR:[190 158 103]
%PhaseCriterion=[60 60 80 80]: NL [224 270 210];
%PhaseCriterion=[60 60 82 82]: NL [224 287 193];
%PhaseCriterion=[60 60 85 85]: NL [224 314 166];
%PhaseCriterion=[55 55 79 79]: NL [187 273 244];
%PhaseCriterion=[55 55 82 82]: NL [187 324 193];
%PhaseCriterion=[60 60 90 90]: NL [224 270 210];

PhaseCriterion=[60 60 88 88];%
IsCorrectOrErrorOrAllTrials=3;%1 for correct trials, 2 for error trials , 3 for all trials
num_neuron_ForDecoding=220; 
IsExcludeNLNeurons=0;
IsNormalizedData=1;
num_cv_splits=40;
bin_width=500;%define the bin width for each sliding window  200
if IsCorrectOrErrorOrAllTrials==1||IsCorrectOrErrorOrAllTrials==2
    num_times_to_repeat_each_label_per_cv_split= 1;
elseif IsCorrectOrErrorOrAllTrials==3
    num_times_to_repeat_each_label_per_cv_split= 2;
end
step_size = 100;
if IsCalculateTCTDecodingResults==1
    GroupNum=3;
    NullDistributionNum =10;
    num_resample_runs = 5;%50 for normal decoding, 10 for null-distribution decoding
    PlotFigure=0;
    step_size = 100;
else
    if IsShffleDecoding==1
        GroupNum=6;
        NullDistributionNum = 5;
        num_resample_runs = 10;
        PlotFigure=0;
    else
        GroupNum=1;
        NullDistributionNum =10;
        num_resample_runs = 5;%50 for normal decoding, 10 for null-distribution decoding
        PlotFigure=1;
    end
end
StartTime=1;%start from StartTime second after to 4s baseline(which means 4-StartTime=1s before the sample odor)
NotComputeLastSecondNum=6+2;
%%
UnitSummaryFile=dir(['*' TargetBrainID '-DPA-AllUnitsSummary*.mat']);
for iFile=1:size(UnitSummaryFile,1)%go through each group of data
    Filename=UnitSummaryFile(iFile).name(1:end-4);
    load(UnitSummaryFile(iFile).name);
    
    GroupID='-NL';
    IsChR=regexpi(Filename,'ChR');
    if ~isempty(IsChR)
        GroupID='-ChR';
        num_neuron_ForDecoding=170; 
    end
    IsNpHR=regexpi(Filename,'NpHR');
    if ~isempty(IsNpHR)
        GroupID='-NpHR';
        num_neuron_ForDecoding=100; 
    end
    TimeGain=TotalUnitSplitData.TimeGain{1}(1);
    TrialLaserDelay=TotalUnitSplitData.TrialLaserDelay{1};
    LaserPhase=unique(TrialLaserDelay(:,2));%2 for laser in block design
    IsLaserGroup=max(LaserPhase);%0 no laser condition, 1 for laser condition  
    %% get the training day ID
    [MiceID,TargetTrainingDay]=GetTrainingDay(TotalUnitSplitData);
    DayBasedPerformanceNeuron=DayBasedPerAndNeuronInfo(TotalUnitSplitData,TargetTrainingDay);
    if IsExcludeNLNeurons==1&&IsLaserGroup==0
        disp('---- Excluded No Laser Well-Trained Neurons ----')
        ExcludedTrainingDayPerformanCriterion=91.5;% if 100, do not excluded any data
        [TargetTrainingDay,ExcludedTrainingDay,ExcludedNeuronIndex]=...
            ExcludedTrainingDayAccordingToPer(TotalUnitSplitData,TargetTrainingDay,ExcludedTrainingDayPerformanCriterion);
    end
    %Filter the Training day for diffreent learning phase
    [PhasesNeuronID,LearningdPhaseDayBasedPerformance,WellTrainedPhasePerformance]=...
        FilterTrainingDayForDifferentPhases(TotalUnitSplitData,TargetTrainingDay,PhaseCriterion,100);
    %plot averaged performance for difference phases
    if PlotSingleDayPerformance==1
        PlotPhasePerformance(PhasesNeuronID,'Cross phase performance')
        saveas(gcf,'Phase-performance.fig')
        saveas(gcf,'Phase-performance.png')
        close all
    end
    %%
    if PlotSingleDayPerformance==1
        for iPhase=2%plot the performance in each learning phase
            LearningPhase=['Phase-' num2str(iPhase)];
            TargetPhaseDayID=PhasesNeuronID{3,iPhase};
            TargetPhasePerformance=PhasesNeuronID{4,iPhase};
            PlotTargetPhasePerformanceForDecoding(TargetPhasePerformance,LearningPhase)
            saveas(gcf,[LearningPhase '-Performance'],'fig')
            saveas(gcf,[LearningPhase '-Performance'],'png')
            close all
            %plot block based performance for each day in the target phase
            for iDay=1:size(PhasesNeuronID{4,iPhase},1)
                tempDayID= TargetPhaseDayID{iDay};
                Ind=regexpi(tempDayID,'day');
                PlotDecodingPhasePerformance(TargetPhasePerformance{iDay},[LearningPhase '-' tempDayID(7:Ind+3)],'DPA Task');
                saveas(gcf,[LearningPhase '-' PhasesNeuronID{3,iPhase}{iDay} '-Performance'],'fig')
                saveas(gcf,[LearningPhase '-' PhasesNeuronID{3,iPhase}{iDay} '-Performance'],'png')
                close all
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    for iPhase=AllPhases%go through each phase
        LearningPhase=['Phase-' num2str(iPhase)];
        %% extract the neurons in this behavioral phase
        tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,PhasesNeuronID{1,iPhase});
        
        SPlen=min(vertcat(tempTotalUnitSplitData.ShortSPlen{:}));
        MeanTrialLength=SPlen/TimeGain;
        Bin_Num=length(0:step_size:MeanTrialLength*1000-bin_width);
        TimeGain=tempTotalUnitSplitData.TimeGain{1}(1);
        TrialLaserDelay=tempTotalUnitSplitData.TrialLaserDelay{1};
        TotalSingleUnitNum=length(tempTotalUnitSplitData.AllSequentialAllSP);
        LaserPhase=unique(TrialLaserDelay(:,2));%2 for laser in block design
        IsLaserGroup=max(LaserPhase);%0 no laser condition, 1 for laser condition
        %%
        for iIsLaserTrial=1:length(LaserPhase)%go through laser or no laser trial
            disp('---Current Loop Number/Total Loop Number---')
            CurrentLoopNum=(iPhase-1)*length(LaserPhase)+iIsLaserTrial;
            disp(['---' num2str(CurrentLoopNum) '/' num2str(length(LaserPhase)*length(AllPhases)) '---'])
            disp(['---- GroupNum-' num2str(GroupNum) '-TotalNullDistributionNum-' num2str(NullDistributionNum) '----'] )
            IsLaserTrial=LaserPhase(iIsLaserTrial);
            [TitleName,Classifier]=ConstructNDTDecodingTitle(TargetBrainID,Decodingclassifier,DecodingForSamTestDecisionTrialType...
                ,IsShffleDecoding,num_resample_runs,num_cv_splits,num_times_to_repeat_each_label_per_cv_split...
                ,num_neuron_ForDecoding,0,bin_width,IsNormalizedData,GroupID,LearningPhase,[],IsCorrectOrErrorOrAllTrials...
                ,IsExcludeNLNeurons,IsCalculateTCTDecodingResults,step_size,7,1);
            disp(['----- ' TitleName '-----'])
            %% Step 1. Construct raw data
            disp('-----Step 1 Construct raw data-----')
            %Construct the raw trial matrix
            binned_data=cell(1,TotalSingleUnitNum);
            stimulus_ID=cell(1,TotalSingleUnitNum);
            AllNeuronTrialNum=zeros(1,TotalSingleUnitNum);
            for iNeuron=1:TotalSingleUnitNum% go through each units
                SequentialAllSP=tempTotalUnitSplitData.AllSequentialAllSP{iNeuron};
                TrialsJudgement=tempTotalUnitSplitData.TrialsJudgement{iNeuron}(1:size(SequentialAllSP,2),:);
                TrialLaserDelay=tempTotalUnitSplitData.TrialLaserDelay{iNeuron}(1:size(SequentialAllSP,2),:);
                %% get the target trial index according to the identity of the first odorant
                [temp_stimulus_ID,TrialIndex]= GetNDTTrialID(DecodingForSamTestDecisionTrialType,TrialsJudgement,TrialLaserDelay,IsLaserTrial,IsCorrectOrErrorOrAllTrials);
                AllNeuronTrialNum(iNeuron)=length(TrialIndex);
                %% construct binned data for each neuron
                if length(TrialIndex)>=num_cv_splits*num_times_to_repeat_each_label_per_cv_split*2
                    stimulus_ID{1,iNeuron}=temp_stimulus_ID;
                    binned_data{1,iNeuron}=ConstructBinnedDataForNDT(SequentialAllSP,TrialIndex,bin_width,step_size,MeanTrialLength,Decodingclassifier);
                end
            end
            %% Step 2: Create a datasource object
            %disp('-----Step 2 Create a datasource object-----')
            % create the basic datasource object
            if Decodingclassifier==2
                binned_site_info.binning_parameters.bin_width=bin_width;
                save('PNBBinnedData','binned_data','binned_site_info')
                % if using the Poison Naive Bayes classifier, load the data as spike counts by setting the load_data_as_spike_counts flag to 1
                ds = basic_DS('PNBBinnedData', stimulus_ID, num_cv_splits, 1);
            else
                ds = basic_DS(binned_data, stimulus_ID, num_cv_splits);
            end
            % can have multiple repetitions of each label in each cross-validation split (which is a faster way to run the code that uses most of the data)
            ds.num_times_to_repeat_each_label_per_cv_split= num_times_to_repeat_each_label_per_cv_split;
            %defien wether perform decoding analysis with shuffle data
            ds.randomly_shuffle_labels_before_running=IsShffleDecoding;
            % optionally can specify particular sites to use
            ds.sites_to_use = find_sites_with_k_label_repetitions(stimulus_ID, num_cv_splits);
            if num_neuron_ForDecoding>=length(ds.sites_to_use)
                num_neuron_ForDecoding=length(ds.sites_to_use)-1;
            end
            %define the neuron number used to perform decoding analysis
            ds.num_resample_sites =num_neuron_ForDecoding;
            %define the event period used to perform decoding
            BinStart=StartTime*1000/step_size+1;
            BinEnd=floor(MeanTrialLength-NotComputeLastSecondNum)*1000/step_size;
            ds.time_periods_to_get_data_from = num2cell(BinStart:BinEnd);
            %% Step 3.  Create a feature preprocessor object
            %disp('-----Step 3 Create a feature preprocessor object-----')
            % create a feature preprocess that z-score normalizes each feature
            if IsNormalizedData==1
                the_feature_preprocessors{1} = zscore_normalize_FP;
            else
                the_feature_preprocessors=[];
            end
            %% Step 4.  Create a classifier object
            %disp('-----Step 4 Create a classifier object-----')
            % select a classifier
            if Decodingclassifier==1
                the_classifier = max_correlation_coefficient_CL;
            elseif Decodingclassifier==2
                % use a poisson naive bayes classifier (note: the data needs to be loaded as spike counts to use this classifier)
                the_classifier = poisson_naive_bayes_CL;
            elseif Decodingclassifier==3
                % use a support vector machine (see the documentation for all the optional parameters for this classifier)
                the_classifier = libsvm_CL;
            end
            %% Step 5.  create the cross-validator
            %disp('-----Step 5 create the cross-validator-----')
            if Decodingclassifier~=2%MCC, SVM
                the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);
            else%integers were needed for PNB classifier
                the_cross_validator = standard_resample_CV(ds, the_classifier);
            end
            the_cross_validator.num_resample_runs = num_resample_runs;
            %more accurate results, but to save time we are using a small number here
            if IsCalculateTCTDecodingResults==0
                the_cross_validator.test_only_at_training_times = 1;
            end
            %% Step 6.  Run the decoding analysis
            disp('-----Step 6 Run the decoding analysis-----')
            % run the decoding analysis  run_cv_decoding
            the_cross_validator.display_progress.zero_one_loss=0;
            the_cross_validator.display_progress.resample_run_time=0;
            Path=pwd;
            for iNullDis=1:NullDistributionNum
                DECODING_RESULTS = the_cross_validator.run_cv_decoding; %run_cv_decoding
                %decoding_results [num_resample_runs x num_cv_splits x num_training_times x num_test_times]
                save([TitleName '-Group' num2str(GroupNum) '-' num2str(iNullDis)], 'DECODING_RESULTS');
            end
            save(TitleName , 'DECODING_RESULTS');
            if ~isempty(ShuffleDecodingDir)%exist('ShuffleDecodingDir','var')
                ShuffleDecodingResultsDir=[Path '\' ShuffleDecodingDir '\'];
            else
                ShuffleDecodingResultsDir=[];
            end
            %% Step 7.  Plot the basic results
            disp('-----Step 7 Plot the basic results -----')
            disp(['----- ' TitleName '-----'])
            % which results should be plotted (only have one result to plot here)
            
            if IsShffleDecoding~=1&&PlotFigure==1
                result_names{1} = TitleName ;
                plot_obj = plot_standard_results_object(result_names);
                %plot STD across resample runs
                plot_obj.errorbar_file_names={TitleName};
                plot_obj.p_values=[];
                % optional argument, can plot different types of results
                %plot_obj.result_type_to_plot = 2;  % for example, setting this to 2 plots the normalized rank results
                TimeBinNumber=size(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results,1);
                ProceedingBinNum=bin_width/step_size;
                X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
                X=X+ProceedingBinNum*step_size/1000;
                plot_obj.plot_time_intervals={X};
                plot_obj.xlabel_name='Time(s)';
                plot_obj.legend_names={[Classifier '-Sample Decoding']};
                plot_obj.plot_inds={1:TimeBinNumber};
                plot_obj.errorbar_type_to_plot=1;
                plot_obj.significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
                
                plot_obj.plot_results; % actually plot the results  plot_results
                title(TitleName)
                text(1.5,80,['NeuronNum=' num2str(num_neuron_ForDecoding)],'fontsize',12,'color',[0 0 1])
                saveas(gcf,TitleName ,'fig')%
                saveas(gcf,TitleName ,'png')%
                close all
            end
            if IsCalculateTCTDecodingResults==1&&IsShffleDecoding~=1&&PlotFigure==1
                result_names{1} = TitleName;
                plot_obj = plot_standard_results_TCT_object(result_names);
                plot_obj.result_file_name=TitleName;
                plot_obj.plot_time_intervals=X;
                plot_obj.xlabel_name='Test time (s)';
                plot_obj.ylabel_name='Train time(s)';
                plot_obj.font_size=10;
                plot_obj.significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
                plot_obj.display_TCT_movie=0;
                plot_obj.color_result_range=[40 85];
                plot_obj.plot_results;  % plot_results  plot_standard_results_TCT_object
                axis([-0.5 8 -0.5 8])
                title(TitleName)
                saveas(gcf,[TitleName '-TCT'] ,'fig')%
                saveas(gcf,[TitleName '-TCT'] ,'png')%
                print(gcf,'-depsc',[TitleName '-TCT.ai'])
                close all
            end
            save([TitleName '-All Parameters'],'DECODING_RESULTS','binned_data','stimulus_ID','DecodingForSamTestDecisionTrialType'...
                ,'IsShffleDecoding','num_resample_runs','num_cv_splits','num_neuron_ForDecoding','PhasesNeuronID','Classifier','X'...
                ,'bin_width','step_size','UnitSummaryFile','StartTime','OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN'...
                ,'TitleName','PhaseCriterion','IsCorrectOrErrorOrAllTrials','-v7.3');
            clearvars 'stimulus_ID' 'binned_data' 'ds' 'the_cross_validator' 'DECODING_RESULTS'
        end
    end    
end