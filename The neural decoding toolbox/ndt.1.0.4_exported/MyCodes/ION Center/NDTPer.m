%the code was used to calculate the decoding efficiency with the Neural
%Decoding Toolbox in ION Computing center
% addpath(genpath('/home/qcheng/personaldata/uploaddata/Decoding'))%ION computing center
UnitSummaryFile=dir('*DPA-AllUnitsSummary*.mat');
for iFile=1:size(UnitSummaryFile,1)%go through each group of data
    Filename=UnitSummaryFile(iFile).name(1:end-4);
    disp(Filename)
%     disp(datetime)
    WorkerNum=10;
    %%
    load(Filename);
    GroupID='-NL';
    IsChR=regexpi(Filename,'ChR');
    if ~isempty(IsChR)
        GroupID='-ChR';
    end
    IsNpHR=regexpi(Filename,'NpHR');
    if ~isempty(IsNpHR)
        GroupID='-NpHR';
    end
           
    TargetBrainID='AI';%define the brain area for summary
    PlotSingleDayPerformance=0;
    IsShffleDecoding=1;
    Decodingclassifier=1;%1 for max_correlation_coefficient_CL£¬2 for poisson_naive_bayes_CL£¬3 for support vector machine
    DecodingForSamTestDecisionTrialType=1;% Decoding for 1-sample odor,2-test odor, 3-decision(FC or CR in nonpair trials), 4-trial type(Pair-Nonpair)
    ShuffleDecodingDir=[];%'ShuffleDecoding-AI-for Sample Odor-10-10-150-470-MCC';%define the directory of shuffle decoding results files
    IsCalculateTCTDecodingResults=1;
    AllPhases=[1 2 3];%define the learning phase to be calculated [1 2 3]
    for PairOrNonPairTrials=3%1 for pairing trials, 2 for non-pairing trials,3 for all trials
        IsCorrectOrErrorOrAllTrials=3;%1 for correct trials, 2 for error trials , 3 for all trials
        IsExcludeNLNeurons=0;
        IsNormalizedData=1;
        PhaseCriterion=[60 60 79 79];%[60 60 79 79];
        num_neuron_ForDecoding=100; %370 for all and 242 selective neuron for block design 470/227
        num_cv_splits=40;
        bin_width=500;%define the bin width for each sliding window  200
        if IsCorrectOrErrorOrAllTrials==1||IsCorrectOrErrorOrAllTrials==2||PairOrNonPairTrials<3
            num_times_to_repeat_each_label_per_cv_split= 1;
        elseif IsCorrectOrErrorOrAllTrials==3
            num_times_to_repeat_each_label_per_cv_split= 2;
        end
        step_size = 100;
        if IsCalculateTCTDecodingResults==1
            GroupNum=2;
            NullDistributionNum =100;
            num_resample_runs = 10;%50 for normal decoding, 10 for null-distribution decoding
            step_size = 100;
        else
            if IsShffleDecoding==1
                GroupNum=1;
                NullDistributionNum = 50;
                num_resample_runs = 20;
            else
                GroupNum=1;
                NullDistributionNum =10;
                num_resample_runs = 5;%50 for normal decoding, 10 for null-distribution decoding
            end
        end
        StartTime=1;%start from 2 second after to 4s baseline(which means 4-2=2s before the sample odor)
        NotComputeLastSecondNum=6+2;
        
        TimeGain=TotalUnitSplitData.TimeGain{1}(1);
        BaselinePer=21:4*TimeGain; %2 seconds before sample onset        
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
            PlotPhasePerformance(PhasesNeuronID)
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
        CrossPhaseDecodingAccuray=cell(3,3);
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
                CurrentLoopNum=3*length(LaserPhase)+(iPhase-1)*length(LaserPhase)+iIsLaserTrial;
                disp(['---' num2str(CurrentLoopNum) '/' num2str(length(LaserPhase)*length(AllPhases)) '---'])
                disp(['---- GroupNum-' num2str(GroupNum) '-TotalNullDistributionNum-' num2str(NullDistributionNum) '----'] )
                IsLaserTrial=LaserPhase(iIsLaserTrial);
                [TitleName,Classifier]=ConstructNDTDecodingTitle(TargetBrainID,Decodingclassifier,DecodingForSamTestDecisionTrialType...
                    ,IsShffleDecoding,num_resample_runs,num_cv_splits,num_times_to_repeat_each_label_per_cv_split...
                    ,num_neuron_ForDecoding,0,bin_width,IsNormalizedData,GroupID,LearningPhase,[],IsCorrectOrErrorOrAllTrials...
                    ,IsExcludeNLNeurons,IsCalculateTCTDecodingResults,step_size,7,1,PairOrNonPairTrials);
                disp(['----- ' TitleName '-----'])
                %% Step 1.  Construct raw data
                disp('-----Step 1 Construct raw data-----')
                %Construct the raw trial matrix
                binned_data=cell(1,TotalSingleUnitNum);
                stimulus_ID=cell(1,TotalSingleUnitNum);
                AllNeuronTrialNum=zeros(1,TotalSingleUnitNum);
                for iNeuron=1:TotalSingleUnitNum% go through each units
                    SequentialAllSP=tempTotalUnitSplitData.AllSequentialAllSP{iNeuron};
                    TrialsJudgement=tempTotalUnitSplitData.TrialsJudgement{iNeuron}(1:size(SequentialAllSP,2),:);
                    TrialLaserDelay=tempTotalUnitSplitData.TrialLaserDelay{iNeuron}(1:size(SequentialAllSP,2),:);
                    %%
                    %get the target trial index according to the identity of the first odorant
                    [temp_stimulus_ID,TrialIndex]= GetNDTTrialID(DecodingForSamTestDecisionTrialType,TrialsJudgement,TrialLaserDelay,IsLaserTrial...
                        ,IsCorrectOrErrorOrAllTrials,PairOrNonPairTrials,SequentialAllSP,BaselinePer,SPlen,TimeGain);
                    AllNeuronTrialNum(iNeuron)=length(TrialIndex);
                    %%
                    %construct binned data for each neuron
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
                %disp(datetime)
                % run the decoding analysis  run_cv_decoding
                the_cross_validator.display_progress.zero_one_loss=0;
                the_cross_validator.display_progress.resample_run_time=0;
                
                poolobj = gcp('nocreate'); % If no pool, do not create new one.
                if isempty(poolobj)
                    myCluster=parcluster('local'); myCluster.NumWorkers=WorkerNum; parpool(myCluster,WorkerNum)
                end
                %p = gcp(parpool('local',20));
                %delete(gcp)
                for idx = 1:NullDistributionNum
                    f(idx) = parfeval(@the_cross_validator.run_cv_decoding,1);
                end
                for iNullDis = 1:NullDistributionNum
                    [~,DECODING_RESULTS] = fetchNext(f);  % Collect the results as they become available.
                    save([TitleName '-' num2str(GroupNum) '-' num2str(iNullDis)], 'DECODING_RESULTS','-v7.3');
                end
                disp('Computing End')
%                 disp(datetime)
                save([TitleName '-All Parameters'],'DECODING_RESULTS','binned_data','stimulus_ID','DecodingForSamTestDecisionTrialType'...
                    ,'IsShffleDecoding','num_resample_runs','num_cv_splits','num_neuron_ForDecoding','PhasesNeuronID','Classifier'...
                    ,'bin_width','step_size','UnitSummaryFile','StartTime','OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN'...
                    ,'TitleName','PhaseCriterion','PairOrNonPairTrials','-v7.3');
                clearvars 'stimulus_ID' 'binned_data' 'ds' 'the_cross_validator' 'DECODING_RESULTS'
            end
        end
    end
end