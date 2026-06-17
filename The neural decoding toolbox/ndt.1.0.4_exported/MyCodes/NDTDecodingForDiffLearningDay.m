%the code was used to calculate the decoding accuracy with the Neural Decoding Toolbox for different learning day
TargetDayID=[{[1]};{[2]};{3};{[4]};{[5]}];%define the group days used to perform decoding analysis
All_num_neuron_ForDecoding=[46 86 90 50 61];

TargetBrainID='AI';%define the brain area for summary
IsShffleDecoding=0;
Decodingclassifier=1;%1 for max_correlation_coefficient_CL£¬2 for poisson_naive_bayes_CL£¬3 for support vector machine
DecodingForSamTestDecisionTrialType=1;% Decoding for 1-sample odor,2-test odor, 3-decision(FC or CR in nonpair trials), 4-trial type(Pair-Nonpair)
IsPlotTCTDecodingResults=0;
ShuffleDecodingDir=[];%'ShuffleDecoding-AI-for Sample Odor-3-10-100-MCC-NpHR'; define the directory of shuffle decoding results files
PlotMouseBasedPerformance=0;

bin_width=500;%ms
step_size=50;%ms
num_cv_splits=10;%affect the decoding variations, not the absolute the decoding accuracy
num_trial_ForEachCondition=40;
num_times_to_repeat_each_label_per_cv_split= floor(num_trial_ForEachCondition/ num_cv_splits);
if IsShffleDecoding==1
    NullDistributionNum = 200;
    num_resample_runs = 10;
else
    NullDistributionNum =1;
    num_resample_runs = 50;
end
StartTime=0;%start from 2 second after to 4s baseline(which means 4-2=2s before the sample odor)
%%
UnitSummaryFile=dir(['*' TargetBrainID '-DPA-AllUnitsSummary*.mat']);
if size(UnitSummaryFile,1)~=0
    load(UnitSummaryFile.name);
    TimeGain=TotalUnitSplitData.TimeGain{1}(1);
    %% get the Mice ID and training day ID
    [MiceID,TargetTrainingDay]=GetTrainingDay(TotalUnitSplitData);
    %get the performance and neuron ID for each training day
    DayBasedPerformanceNeuron=DayBasedPerAndNeuronInfo(TotalUnitSplitData,TargetTrainingDay);
    %get all the neuron index in the traget training day
    [NeuronIndexInEachTrainingDay,MiceBasedPerformance]=GetNeuronIndexInEachTrainingDay(DayBasedPerformanceNeuron,MiceID);
    %% Plot cross day performance for each mouse
    if PlotMouseBasedPerformance==1
        for iMouse=1:size(MiceBasedPerformance,1)
            PlotCrossDayPerForDayBasedDecoding(MiceBasedPerformance(iMouse,:))
            saveas(gcf,[ 'CrossDayPer-' MiceBasedPerformance{iMouse,1}],'fig')
            saveas(gcf,[ 'CrossDayPer-' MiceBasedPerformance{iMouse,1}],'png')
            close all
        end
    end
    %plot cross day performance of all Mice
    PlotPhasePerformance(NeuronIndexInEachTrainingDay,1)
    saveas(gcf,'Cross day performance.fig')
    saveas(gcf,'Cross day performance.png')
    close all
    %%
    for iTargetDay=1:length(TargetDayID)%go through each target day group
        DayID=ConstructDayID(TargetDayID(iTargetDay));
        %plot average performance in target days
        TargetDayPerformance=NeuronIndexInEachTrainingDay(4,TargetDayID(iTargetDay));
        TargetDayPerformance=vertcat(TargetDayPerformance{:});
        PlotTargetPhasePerformanceForDecoding(TargetDayPerformance,DayID)
        saveas(gcf,[DayID '-Performance'],'fig')
        saveas(gcf,[DayID '-Performance'],'png')
        close all
        %extract the neurons in the target training day
        num_neuron_ForDecoding=All_num_neuron_ForDecoding(iTargetDay);
        TargetNeuronID=NeuronIndexInEachTrainingDay(1,TargetDayID{iTargetDay});
        tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,vertcat(TargetNeuronID{:}));
        %%
        SPlen=min(vertcat(tempTotalUnitSplitData.ShortSPlen{:}));
        MeanTrialLength=SPlen/TimeGain;
        TotalSingleUnitNum=length(tempTotalUnitSplitData.AllSequentialAllSP);
        TrialLaserDelay=tempTotalUnitSplitData.TrialLaserDelay{1};
        LaserPhase=unique(TrialLaserDelay(:,2));%2 for laser in block design
        IsLaserGroup=max(LaserPhase);%0 no laser condition, 1 for laser condition
        %%
        for iIsLaserTrial=1:length(LaserPhase)%go through laser or no laser trial
            IsLaserTrial=LaserPhase(iIsLaserTrial);
            %Construct the raw trial matrix
            [TitleName,Classifier]=ConstructNDTDecodingTitle(TargetBrainID,Decodingclassifier,DecodingForSamTestDecisionTrialType,IsShffleDecoding...
                ,num_resample_runs,num_cv_splits,num_trial_ForEachCondition,IsLaserGroup,num_neuron_ForDecoding,0,bin_width,DayID);
            disp(['----- ' TitleName '-----'])
            %% Step 1.  Construct raw data
            disp('-----Step 1 Construct raw data-----')
            binned_data=cell(1,TotalSingleUnitNum);
            stimulus_ID=cell(1,TotalSingleUnitNum);
            for iNeuron=1:size(tempTotalUnitSplitData.AllSequentialAllSP,1)% go through each neuron
                SequentialAllSP=tempTotalUnitSplitData.AllSequentialAllSP{iNeuron};
                TrialsJudgement=tempTotalUnitSplitData.TrialsJudgement{iNeuron}(1:size(SequentialAllSP,2),:);
                TrialLaserDelay=tempTotalUnitSplitData.TrialLaserDelay{iNeuron}(1:size(SequentialAllSP,2),:);
                %% get the target trial index according to the identity of the first odorant
                [temp_stimulus_ID,TrialIndex]= GetNDTTrialID(DecodingForSamTestDecisionTrialType,TrialsJudgement,TrialLaserDelay...
                    ,IsLaserTrial,num_trial_ForEachCondition);
                %%  construct binned data for each neuron
                if ~isempty(temp_stimulus_ID)
                    stimulus_ID{1,iNeuron}=temp_stimulus_ID;
                    binned_data{1,iNeuron}=ConstructBinnedDataForNDT(SequentialAllSP,TrialIndex,bin_width,step_size,MeanTrialLength,Decodingclassifier);
                end
            end
            %% exclud the neurons with two few trials
            TwoFewTrialNeuronIndex=cellfun(@isempty,stimulus_ID,'uniformoutput',1);
            stimulus_ID(TwoFewTrialNeuronIndex)=[];
            binned_data(TwoFewTrialNeuronIndex)=[];
            %% Step 2: Create a datasource object
            disp('-----Step 2 Create a datasource object-----')
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
            %define the neuron number used to perform decoding analysis
            ds.num_resample_sites =num_neuron_ForDecoding;
            %define the event period used to perform decoding
            BinStart=StartTime*1000/step_size+1;
            BinEnd=floor(MeanTrialLength-4)*1000/step_size;
            ds.time_periods_to_get_data_from = num2cell(BinStart:BinEnd);
            %% Step 3.  Create a feature preprocessor object
            disp('-----Step 3 Create a feature preprocessor object-----')
            % create a feature preprocess that z-score normalizes each feature
            the_feature_preprocessors{1} = zscore_normalize_FP;
            %% Step 4.  Create a classifier object
            disp('-----Step 4 Create a classifier object-----')
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
            disp('-----Step 5 create the cross-validator-----')
            if Decodingclassifier~=2%integers were needed for PNB classifier
                the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);
            else
                the_cross_validator = standard_resample_CV(ds, the_classifier);%MCC, SVM
            end
            the_cross_validator.num_resample_runs = num_resample_runs;
            %more accurate results, but to save time we are using a small number here
            if IsPlotTCTDecodingResults==0
                the_cross_validator.test_only_at_training_times = 1;
            end
            %% Step 6.  Run the decoding analysis
            disp('-----Step 6 Run the decoding analysis -----')
            % run the decoding analysis  run_cv_decoding
            the_cross_validator.display_progress.zero_one_loss=0;
            Path=pwd;
            if IsShffleDecoding==1
                mkdir(TitleName)
                ShuffleDecodingResultsDir=[Path '\' TitleName];
                cd(ShuffleDecodingResultsDir)
                for iNullDis=1:NullDistributionNum
                    DECODING_RESULTS = the_cross_validator.run_cv_decoding; %run_cv_decoding
                    %decoding_results [num_resample_runs x num_cv_splits x num_training_times x num_test_times]
                    save([TitleName '-' num2str(iNullDis)], 'DECODING_RESULTS');
                end
            else
                DECODING_RESULTS = the_cross_validator.run_cv_decoding;
                save(TitleName, 'DECODING_RESULTS');
                if ~isempty(ShuffleDecodingDir)%exist('ShuffleDecodingDir','var')
                    ShuffleDecodingResultsDir=[Path '\' ShuffleDecodingDir '\'];
                else
                    ShuffleDecodingResultsDir=[];
                end
            end
            %% Step 7.  Plot the basic results
            disp('-----Step 7 Plot the basic results -----')
            disp(['----- ' TitleName '-----'])
            % which results should be plotted (only have one result to plot here)
            TimeBinNumber=size(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results,1);
            result_names{1} = TitleName;
            if IsShffleDecoding~=1
                % create an object to plot the results
                plot_obj = plot_standard_results_object(result_names);
                %plot STD across resample runs
                plot_obj.errorbar_file_names={TitleName};
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %difine the shuffled decoing results directory for
                %permutation test
                if ~isempty(ShuffleDecodingResultsDir)
                    plot_obj.p_values={ShuffleDecodingResultsDir};
                else
                    plot_obj.p_values=[];
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %plot_obj.p_values={0.01*ones(1,TimeBinNumber)};
                % optional argument, can plot different types of results
                %plot_obj.result_type_to_plot = 2;  % for example, setting this to 2 plots the normalized rank results
                plot_obj.plot_time_intervals={-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-2)-step_size/1000};
                plot_obj.xlabel_name='Time(s)';
                plot_obj.legend_names={[Classifier '-Sample Decoding']};
                plot_obj.plot_inds={1:TimeBinNumber};
                plot_obj.errorbar_type_to_plot=1;
                plot_obj.significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
                
                plot_obj.plot_results; % actually plot the results  plot_results
                title(TitleName)
                text(8.5,80,['NeuronNum=' num2str(num_neuron_ForDecoding)],'fontsize',12,'color',[0 0 1])
                saveas(gcf,TitleName ,'fig')%
                saveas(gcf,TitleName ,'png')%
                close all
            end
            %% Step 8.  Plot the TCT matrix
            if IsPlotTCTDecodingResults==1&&IsShffleDecoding~=1
                plot_obj = plot_standard_results_TCT_object(result_names);
                plot_obj.significant_event_times = 0;   % the time when the stimulus was shown
                plot_obj.plot_results;  % plot the TCT matrix and a movie showing if information is coded by a dynamic population code
            end
            save([TitleName '-All Parameters'],'DECODING_RESULTS','binned_data','stimulus_ID','DecodingForSamTestDecisionTrialType','IsShffleDecoding'...
                ,'num_resample_runs','num_cv_splits','num_trial_ForEachCondition','num_neuron_ForDecoding','bin_width','step_size','UnitSummaryFile');
        end
    end
end