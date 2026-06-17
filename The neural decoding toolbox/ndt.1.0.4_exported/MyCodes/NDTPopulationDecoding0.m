%the code was used to calculate the decoding efficiency with the Neural Decoding Toolbox()
TargetBrainID='AI';%define the brain area for summary
Decodingclassifier=1;%1 for max_correlation_coefficient_CL£¬2 for poisson_naive_bayes_CL£¬3 for support vector machine
DecodingForSamTestDecisionTrialType=1;% Decoding for 1-sample odor,2-test odor, 3-decision(FC or CR in nonpair trials), 4-trial type(Pair-Nonpair)
PickUpNeuronsWithOdorSelectivity=0;

IsShffleDecoding=0;
ShuffleTimes=100;%decoding with shuffle data for calculate the null distribution of decoding power and the P-Value for real data
IsPlotTCTDecodingResults=0;

if IsShffleDecoding==1
    num_resample_runs = 200;
else
    num_resample_runs = 50; %Decoding times
end
% use 20 cross-validation splits (which means that 19 examples of each object are used for training and 1 example of each object is used for testing)
num_cv_splits = 20; %the trial number for each stimulus condition used to perform the decoding analysis; test times

bin_width = 150;
step_size = 50;
%%
UnitSummaryFile=dir([TargetBrainID '-DPA-AllUnitsSummary.mat']);
if size(UnitSummaryFile,1)~=0
    load(UnitSummaryFile.name);
    tempTotalUnitSplitData=TotalUnitSplitData;
    SPlen=min(vertcat(TotalUnitSplitData.ShortSPlen{:}));
    TimeGain=TotalUnitSplitData.TimeGain{1}(1);
    MeanTrialLength=SPlen*1/TimeGain;
    TotalSingleUnitNum=length(tempTotalUnitSplitData.AllSequentialAllSP);
    TrialLaserDelay=TotalUnitSplitData.TrialLaserDelay{1};
    LaserPhase=unique(tempTotalUnitSplitData.TrialLaserDelay{1}(:,2));%2 for laser in block design
    if max(LaserPhase)==1
        IsLaserGroup=1;%0 no laser condition, 1 for laser condition
    elseif max(LaserPhase)==0
        IsLaserGroup=0;%0 no laser condition, 1 for laser condition
    end
    %%
    for IsLaserTrial=1:length(LaserPhase)%go through laser or no laser trial
        [TitleName,Classifier]=ConstructNDTDecodingTitle(TargetBrainID,Decodingclassifier,DecodingForSamTestDecisionTrialType...
            ,IsShffleDecoding,num_resample_runs,num_cv_splits,IsLaserGroup);
        %Construct the raw trial matrix
        binned_data=cell(1,TotalSingleUnitNum);
        stimulus_ID=cell(1,TotalSingleUnitNum);
        AllNeuronTrialNumber=zeros(2,TotalSingleUnitNum);
        for iNeuron=1:TotalSingleUnitNum% go through each units
            SequentialAllSP=tempTotalUnitSplitData.AllSequentialAllSP{iNeuron};
            TrialsJudgement=tempTotalUnitSplitData.TrialsJudgement{iNeuron}(1:size(SequentialAllSP,2),:);
            TrialLaserDelay=tempTotalUnitSplitData.TrialLaserDelay{iNeuron}(1:size(SequentialAllSP,2),:);
            %%
            %get the target trial index according to the identity of the first odorant
            [TrialIndex1,TrialIndex2]= GetTrialIndexForDecoding(DecodingForSamTestDecisionTrialType,TrialsJudgement);     
            TrialType=unique(stimulus_ID{1,iNeuron});
            AllNeuronTrialNumber(1,iNeuron)=length(find(stimulus_ID{1,iNeuron}==TrialType1));
            AllNeuronTrialNumber(2,iNeuron)=length(find(stimulus_ID{1,iNeuron}==TrialType2));
            %%
            %construct binned data for each neuron
            binned_data{1,iNeuron}=ConstructBinnedDataForNDT(SequentialAllSP,TrialIndex,bin_width,step_size,MeanTrialLength);
        end
        NeuronNum=size(binned_data,2);
        %%
        % create the basic datasource object
        %num_cv_splits=min(min(AllNeuronTrialNumber));
        if Decodingclassifier==2
            binned_site_info.binning_parameters.bin_width=bin_width;
            save('PNBBinnedData','binned_data','binned_site_info')
            % if using the Poison Naive Bayes classifier, load the data as spike counts by setting the load_data_as_spike_counts flag to 1
            ds = basic_DS('PNBBinnedData', stimulus_ID, num_cv_splits, 1);
        else
            ds = basic_DS(binned_data, stimulus_ID, num_cv_splits);
        end
        %perform decoding analysis with shuffle data
        if IsShffleDecoding==1
            ds.randomly_shuffle_labels_before_running=1;
            DecodingTimes=ShuffleTimes;
        else%Decoding with real data
            DecodingTimes=1;
        end
        % other useful options:
        
        % can have multiple repetitions of each label in each cross-validation split...
        % (which is a faster way to run the code that uses most of the data)
        %ds.num_times_to_repeat_each_label_per_cv_split = 1;
        ShuffleDecodingResultsDir=[];
        for iDecodingTimes=1:DecodingTimes
            disp('---Shuffle Times/Total Times---')
            disp([iDecodingTimes DecodingTimes])
            
            %%   7.  Create a feature preprocessor object
            % create a feature preprocess that z-score normalizes each feature
            the_feature_preprocessors{1} = zscore_normalize_FP;
            % other useful options:
            % can include a feature-selection features preprocessor to only use the top k most selective neurons
            if PickUpNeuronsWithOdorSelectivity==1
                fp = select_or_exclude_top_k_features_FP;
                fp.num_features_to_use = 100;   % use only the 100 most selective neurons as determined by a univariate one-way ANOVA
                the_feature_preprocessors{2} = fp;
            end
            if size(the_feature_preprocessors,2)>1
                save_file_name=[save_file_name '-top-' num2str(fp.num_features_to_use)];
            end
            %%  8.  Create a classifier object
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
            %%  9.  create the cross-validator
            if Decodingclassifier~=2%integers were needed for PNB classifier
                the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);
            else
                the_cross_validator = standard_resample_CV(ds, the_classifier);
            end
            %test times
            the_cross_validator.num_resample_runs = num_resample_runs;  % usually more than 2 resample runs are used to get...
            %more accurate results, but to save time we are using a small number here
            % other useful options:
            % can greatly speed up the run-time of the analysis by not creating a full TCT matrix (i.e., only trainging and testing the
            %classifier on the same time bin)
            if IsPlotTCTDecodingResults==0
                the_cross_validator.test_only_at_training_times = 1;
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%  10.  Run the decoding analysis
            % run the decoding analysis
            DECODING_RESULTS = the_cross_validator.run_cv_decoding;
            %decoding_results [num_resample_runs x num_CV_splits x num_training_times x num_test_times]
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            TimeBinNumber=size(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results,1);
            %%  11.  Save the results
            if IsShffleDecoding==1
                if iDecodingTimes==1
                    mkdir('ShuffleDecodingResults')
                end
                cd([Path '\' 'ShuffleDecodingResults'])
                ShuffleDecodingResultsDir=[Path '\' 'ShuffleDecodingResults'];
                % save the results
                save([save_file_name '-' num2str(iDecodingTimes)], 'DECODING_RESULTS');
            else
                save(save_file_name, 'DECODING_RESULTS');
            end
        end
        cd(Path)
        save([save_file_name '-ResultsDirectory'],'ShuffleDecodingResultsDir')
        if IsShffleDecoding~=1
            ShuffleDecodingDir=dir('*ResultsDirectory.mat');
            if size(ShuffleDecodingDir)>0
                load(ShuffleDecodingDir.name)
                %%  12.  Plot the basic results
                % which results should be plotted (only have one result to plot here)
                result_names{1} = save_file_name;
                
                % create an object to plot the results
                plot_obj = plot_standard_results_object(result_names);
                %plot STD across resample runs
                plot_obj.errorbar_file_names(1, :)=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.stdev.over_resamples';
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
                plot_obj.plot_time_intervals={-4:step_size/1000:(TimeBinNumber*step_size/1000-4)-step_size/1000};
                plot_obj.xlabel_name='Time(s)';
                plot_obj.legend_names={[Classifier '-Sample Decoding']};
                plot_obj.plot_inds={1:round(21.5/(step_size/1000))};
                plot_obj.significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
                
                plot_obj.plot_results;   % actually plot the results
                text(-3.5,95,['NeuronNum=' num2str(NeuronNum)],'fontsize',14,'color',[0 0 1])
                saveas(gcf,save_file_name ,'fig')%
                saveas(gcf,save_file_name,'png')%
                close all
                
                disp(['Decoding with-' Classifier '-Classifier'])
                %%  13.  Plot the TCT matrix
                if IsPlotTCTDecodingResults==1
                    plot_obj = plot_standard_results_TCT_object(result_names);
                    
                    plot_obj.significant_event_times = 0;   % the time when the stimulus was shown
                    
                    % optional parameters when displaying the TCT movie
                    %plot_obj.movie_time_period_titles.title_start_times = [-500 0];
                    %plot_obj.movie_time_period_titles.title_names = {'Fixation Period', 'Stimulus Period'}
                    
                    plot_obj.plot_results;  % plot the TCT matrix and a movie showing if information is coded by a dynamic population code
                end
            end
        end
        save(save_file_name,'DECODING_RESULTS','AllNeuronTrialNumber')
    end
end