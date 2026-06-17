%the code was used to calculate the decoding efficiency with the Neural Decoding Toolbox
% addpath(genpath('/home/qcheng/personaldata/uploaddata/Decoding'))%ION computing center
clear;clc;close all
%
TargetBrainID='AI';%define the brain area for summary
UnitSummaryFile=dir(['*' TargetBrainID '-DPA-AllUnitsSummary*.mat']);
for iFile=[2]%:size(UnitSummaryFile,1)%go through each group of data
    Filename=UnitSummaryFile(iFile).name(1:end-4);
    disp(Filename)
%     disp(datetime)
    %TargetDayID=[{[1]};{[2]};{[3]};{[4 5]}];%;{[5]}define the group days used to perform decoding analysis
    TargetDayID=[{[1 2 3 4 5]}]; %
    WorkerNum=10;

    for IsCorrectOrErrorOrAllTrials=3%1 for correct trials, 2 for error trials , 3 for all trials          

        num_neuron_ForDecoding=140; 
        AddSustainedNeuronWithSigBinNum=[1]; % add selective neurons to non-selective pools with target bin number having sustained 
        OnlyWithOrAddTargetSigBinNum=1; % 1 for only with target neurons with specific sig bins, 2 for add  target neurons to non-selective neurons                                     
                                             % 1 second odor selectivity  during delay period, 0 for non-selective neurons
        ExcludeTransientSustainedNeu=0; % 0 for not exclude, 1 for excluding transient neurons, 2 for exclude sustained neurons
    	ExcludeNeuronWithReversedOdorSelectivity=0;%1 delay reversed selec neu; 2 sample-delay reversed selec neu; 3 both 1 and 2;        
                                                  % ChR-569-31=538; NL:704-13=691; NpHR:451-5=446; %delay reversed selective neurons
                                                  % ChR-569-42=527; NL-704-29=675; NpHR-451-19=432;$Sample-Delay reversed selective neurons
                                                  % ChR-569-54=515; NL:704-32=672; NpHR-451-20=431;%3 for both    	
        IsShffleDecoding=0;
        IsCalculateTCTDecodingResults=1;
        CellType=[1];% 1 for all neurons, 2 for pyramidal neurons, 3 for interneurons    	
        PairOrNonPairTrials=3;%1 for pairing trials, 2 for non-pairing trials,3 for all trials
        Decodingclassifier=1;%:3%11 for max_correlation_coefficient_CL£¬2 for poisson_naive_bayes_CL£¬3 for support vector machine        
        IsNormalizedData=1;
        DecodingForSamTestDecisionTrialType=1;% Decoding for 1-sample odor,2-test odor, 3-decision(FC or CR in nonpair trials), 4-trial type(Pair-Nonpair)

    
        %Non-selective neuron 296
        %Transient selective neuron 222
        %Sustained selective neuron 51
        %Switched neuron 54

        %  Cross day neuron number
        %  ChR2 group     [160 124 129 100  66],569 in total
        %no-laser group   [113 129,134,166,162],704 in total
        %   NpHR group    [110 100,101, 66, 75],451 in total
        %Day neuron compositon: Day1
               %SustainedNeu:  ChR-21
                              % NL-10
                              %NpHR-4 
               %TransientNeu: ChR-63-97
                              % NL-36-77
                              %NpHR-27-83
               %SwitchNeu:   % ChR-19
                              % NL-4
                              %NpHR-0 

        %For reversed selectivity neuron number in each day
        %ChR:  Day1-160-19; Day2-132-19; Day3-125-13; Day4-5-176-23;
        %   :  31
        % NL:  Day1-113-4; Day2-129-13; Day3-134-8;  Day4-5-328-24;;
        %   :  13
        %NpHR: Day1-110-0; Day2-100-7;  Day3=101-5;  Day4-5-141-10;
        %   :  5
 
        %1 for equal in specific bin
        %   ChR2 group    [214 176,101,58,39,14],602 in total
        %no-laser group   [276 197,129,61,28,13],704 in total
        %   NpHR group    [209 124, 60,36,15, 7],451 in total
        %after Bonferroni correction
        %   ChR2 group    [296 222(153 69),29,22(16 6)],569 in total
        %no-laser group   [423 228(148 80),31,22(13 9)],704 in total
        %   NpHR group    [300 124(82  42),19, 8(4 4)] ,451 in total  
        %Exclude switched neuron
        %ChR:  Trans-222-186=36; Sus-51-33=18;
        %NL:   Trans-228-204=24; Sus-53-45=8;
        %NpHR: Trans-124-109=15; Sus-27-22=5;

                  %ExcTransientNeu  ExcSustainedNeu  ExcSwitchedNeu
               %ChR:     347            518               515
               %NL:      476            651               672
               %NpHR:    327            424               431

        %Neuron Number limited by Error Trial number
                %       10   15    20    25     30     35     40
                %ChR    492  421   390   298    281    228    199
                %NL     585  485   436   373    325    252    198
                %NpHR   431  401   350   328    239    214    168

        if ExcludeNeuronWithReversedOdorSelectivity==1&&length(TargetDayID)>1
           num_neuron_ForDecoding=100;
        elseif ExcludeNeuronWithReversedOdorSelectivity==2&&length(TargetDayID)>1
           num_neuron_ForDecoding=200;
        end
        if IsCorrectOrErrorOrAllTrials==2
            num_neuron_ForDecoding=100;%NpHR-254, NL-244£¬ ChR2-302
        end
        if CellType==2%2 for pyramidal neurons
            num_neuron_ForDecoding=360;
        elseif CellType==3%3 for interneurons
            num_neuron_ForDecoding=80;%95 for three groups
        end
        bin_width=500;%define the bin width for each sliding window 200
        if IsCorrectOrErrorOrAllTrials==1||IsCorrectOrErrorOrAllTrials==3
            num_cv_splits =40; %the trial number for each stimulus condition used to perform the decoding analysis; test times  10 20
        elseif IsCorrectOrErrorOrAllTrials==2
            num_cv_splits =10; %the trial number for each stimulus condition used to perform the decoding analysis; test times  10 20
        end
        if IsCorrectOrErrorOrAllTrials==1||IsCorrectOrErrorOrAllTrials==2||PairOrNonPairTrials<3
            num_times_to_repeat_each_label_per_cv_split= 1;
        elseif IsCorrectOrErrorOrAllTrials==3
            num_times_to_repeat_each_label_per_cv_split= 2;
        end
        if DecodingForSamTestDecisionTrialType==2
            num_times_to_repeat_each_label_per_cv_split= 1;
            if IsCorrectOrErrorOrAllTrials==1
               num_cv_splits =20; %
            elseif IsCorrectOrErrorOrAllTrials==3
               num_cv_splits =40; %
            end
        end
        if IsCalculateTCTDecodingResults==1
            GroupNum=1;
            NullDistributionNum= 10;
            num_resample_runs = 5;%50 for normal decoding, 10 for null-distribution decoding
            step_size = 100;
        else
            step_size = 100;
            if IsShffleDecoding==1
                GroupNum=1;
                NullDistributionNum = 10;
                num_resample_runs = 5;
            else
                GroupNum=1;
                NullDistributionNum =10;
                num_resample_runs = 5;%50 for normal decoding, 10 for null-distribution decoding
            end
        end
        StartTime=0;%start from 2 second after to 4s baseline(which means 4-2=2s before the sample odor)
        NotComputeLastSecondNum=6+2;
        %%
        load(Filename);
        GroupID='NL';
        IsChR=regexpi(Filename,'ChR');
        if ~isempty(IsChR)
            GroupID='ChR';
        end
        IsNpHR=regexpi(Filename,'NpHR');
        if ~isempty(IsNpHR)
            GroupID='NpHR';
        end
        %% get the training day ID
        [MiceID,TargetTrainingDay]=GetTrainingDay(TotalUnitSplitData);
        %get the performance and neuron ID for each training day
        DayBasedPerformanceNeuron=DayBasedPerAndNeuronInfo(TotalUnitSplitData,TargetTrainingDay);
        %get all the neuron index in the traget training day
        [NeuronIndexInEachTrainingDay,MiceBasedPerformance]=GetNeuronIndexInEachTrainingDay(DayBasedPerformanceNeuron,MiceID);
        %% extract the neurons in this specific training day
        for iTargetDay=1:length(TargetDayID)%go through each target day group
            TrainingDayID=ConstructDayID(TargetDayID{iTargetDay});
            TrainingDayID=regexprep(TrainingDayID,'  ','-','ignorecase');
            %% extract the neurons in this specific training day
            TargetNeuronID=NeuronIndexInEachTrainingDay(1,TargetDayID{iTargetDay});
            tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,vertcat(TargetNeuronID{:}));
            TimeGain=tempTotalUnitSplitData.TimeGain{1}(1);            

            if ExcludeNeuronWithReversedOdorSelectivity==1
                [NeuronIDWithDelayReversedOdorSelectivity,NonSelectiveNeuID,SampleDelayReversedSelectivityNeuID]...
                 =FilterNeuronIDWithReversedOdorSelectivity(tempTotalUnitSplitData,TimeGain,OdorMN,DelayMN);
                tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,NeuronIDWithDelayReversedOdorSelectivity);
                disp(['---- Excluded Neurons With reversed odor selectivity-' num2str(length(NeuronIDWithDelayReversedOdorSelectivity)) '----'])
            elseif ExcludeNeuronWithReversedOdorSelectivity==2
                [NeuronIDWithDelayReversedOdorSelectivity,NonSelectiveNeuID,SampleDelayReversedSelectivityNeuID]...
                 =FilterNeuronIDWithReversedOdorSelectivity(tempTotalUnitSplitData,TimeGain,OdorMN,DelayMN);
                tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,SampleDelayReversedSelectivityNeuID);
                disp(['---- Excluded Neurons With sample-delay reversed odor selectivity-' num2str(length(SampleDelayReversedSelectivityNeuID)) '----'])
           elseif ExcludeNeuronWithReversedOdorSelectivity==3
                [NeuronIDWithDelayReversedOdorSelectivity,NonSelectiveNeuID,SampleDelayReversedSelectivityNeuID]...
                 =FilterNeuronIDWithReversedOdorSelectivity(tempTotalUnitSplitData,TimeGain,OdorMN,DelayMN);

                AllReversedSelecNeuID=union(NeuronIDWithDelayReversedOdorSelectivity,SampleDelayReversedSelectivityNeuID);
                tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,AllReversedSelecNeuID);
                AllReversedSelectiveNeuNum=length(AllReversedSelecNeuID);
                disp(['---- Excluded delay reversed selec and sample-delay reversed selec neu-' num2str(AllReversedSelectiveNeuNum) '----'])
            elseif ExcludeNeuronWithReversedOdorSelectivity==4
                [NeuronIDWithDelayReversedOdorSelectivity,NonSelectiveNeuID,SampleDelayReversedSelectivityNeuID]...
                =FilterNeuronIDWithReversedOdorSelectivity(tempTotalUnitSplitData,TimeGain,OdorMN,DelayMN);

                AllReversedSelecNeuID=union(NeuronIDWithDelayReversedOdorSelectivity,SampleDelayReversedSelectivityNeuID);
                tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,AllReversedSelecNeuID);
                disp(['---- Decoding only With reversed odor selectivity-' num2str(length(AllReversedSelecNeuID)) '----'])
            end            
            if exist('DeleteUnstableNeuronID','var')
                disp(['---- Excluded Unstable Neurons-' num2str(length(DeleteUnstableNeuronID{iFile})) '----'])
                tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,DeleteUnstableNeuronID{iFile});
            end              
            %%
            if CellType>1%identify the cell type with the waveform,1 for all neurons, 2 for pyramidal neurons, 3 for interneurons
                AllWaveForm=TotalUnitSplitData.WaveForm;
                Threshold=350;%threshold seperate fast spiking interneuron and pyramidal neurons
                [AllPeakTroughDuration,FSIID,PCID]=IdentifyCellTypeBasedOnWaveform(AllWaveForm,Threshold);
                if CellType==2%2 for pyramidal neurons
                    tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,PCID);
                elseif CellType==3%3 for interneurons
                    tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,FSIID);
                end
            end
            %% excluded unstable neuron index
            if exist('DeleteBaseLineUnstableNeuronID','var')
                disp(['---- Excluded Unstable Neurons-' num2str(length(DeleteBaseLineUnstableNeuronID)) '----'])
                tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,DeleteBaseLineUnstableNeuronID);
            end
            %%
            SPlen=min(vertcat(tempTotalUnitSplitData.ShortSPlen{:}));
            MeanTrialLength=SPlen*1/TimeGain;            
            LaserPhase=unique(tempTotalUnitSplitData.TrialLaserDelay{1}(:,2));%2 for laser in block design
            IsLaserGroup=max(LaserPhase);%0 no laser condition, 1 for laser condition
            for iIsLaserTrial=1:length(LaserPhase)%go through laser or no laser trial
                disp('---Current Loop Number/Total Loop Number---')
                disp(['---' num2str(iIsLaserTrial) '/' num2str(length(LaserPhase)) '---'])
                disp(['---- GroupNum-' num2str(GroupNum) '-TotalNullDistributionNum-' num2str(NullDistributionNum) '----'] )
                IsLaserTrial=LaserPhase(iIsLaserTrial);
                
                if ExcludeTransientSustainedNeu>0                    
                    [~,~,DelaySigBinNum,~,~]=ConstructNeuronIDWithSpecificSustainedNeu(tempTotalUnitSplitData,TimeGain,DelayMN...
                    ,1,0,IsLaserTrial,IsCorrectOrErrorOrAllTrials,PairOrNonPairTrials);
                    if ExcludeTransientSustainedNeu==1%exclude transient selective neurons
                        TransientNeuID=find(DelaySigBinNum==1|DelaySigBinNum==2);
                        tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,TransientNeuID);     
                        disp(['-----Exclude transient selective neurons-' num2str(length(TransientNeuID)) '-----'])
                    elseif ExcludeTransientSustainedNeu==2%exclude sustained selective neurons
                        SustainedNeuID=find(DelaySigBinNum==3|DelaySigBinNum==4|DelaySigBinNum==5);
                        tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,SustainedNeuID);        
                        disp(['-----Exclude sustained selective neurons-' num2str(length(SustainedNeuID)) '-----'])
                    end
                end
                %% add neurons with sustained odor selectivty to no selective neurons
                TotalSingleUnitNum=length(tempTotalUnitSplitData.AllSequentialAllSP);
                IsSustainedOdorSelectiveNeuron=zeros(TotalSingleUnitNum,5);
                TargetNeuronIDWithSpecificSigBin=[];
                if min(AddSustainedNeuronWithSigBinNum)>=0&&max(AddSustainedNeuronWithSigBinNum)<=5
                    disp('-----Pre-processing the odor selectivity for each neuron -----')
                    [TargetNeuronID,IsSustainedOdorSelectiveNeuron,DelaySigBinNum,TargetNeuronIDWithSpecificSigBin,NeuronNumWithDiffSig1SecondBin]...
                        =ConstructNeuronIDWithSpecificSustainedNeu(tempTotalUnitSplitData,TimeGain,DelayMN,DecodingForSamTestDecisionTrialType...
                        ,AddSustainedNeuronWithSigBinNum,IsLaserTrial,IsCorrectOrErrorOrAllTrials,PairOrNonPairTrials);
                    disp(['-----Target sig neuron number-' num2str(length(TargetNeuronIDWithSpecificSigBin)) '-----'])
                    
                    if OnlyWithOrAddTargetSigBinNum==1% only with neurons with specific sig bin during delay
                        TargetNeuronID=TargetNeuronIDWithSpecificSigBin;
                    elseif OnlyWithOrAddTargetSigBinNum==2% target sig neurons with non-selective neurons
                        TargetNeuronID=TargetNeuronID;
                    end
                else
                    TargetNeuronID=1:TotalSingleUnitNum;
                end  
                TotalSingleUnitNum=length(TargetNeuronID); 
                %num_neuron_ForDecoding=floor(TotalSingleUnitNum/10)*10;

                [TitleName,Classifier]=ConstructNDTDecodingTitle('AI',Decodingclassifier,DecodingForSamTestDecisionTrialType...
                ,IsShffleDecoding,num_resample_runs,num_cv_splits,num_times_to_repeat_each_label_per_cv_split,num_neuron_ForDecoding...
                ,0,bin_width,IsNormalizedData,GroupID,[],TrainingDayID,IsCorrectOrErrorOrAllTrials,0,IsCalculateTCTDecodingResults...
                ,step_size,AddSustainedNeuronWithSigBinNum,CellType,PairOrNonPairTrials);
                if ExcludeTransientSustainedNeu==1%exclude transient selective neurons
                    TitleName=[TitleName '-ExcTransientNeu'];
                elseif ExcludeTransientSustainedNeu==2%exclude sustained selective neurons
                    TitleName=[TitleName '-ExcSustainedNeu'];    
                end
                if ExcludeNeuronWithReversedOdorSelectivity==1
                   TitleName=[TitleName '-ExcDelayReversedNeu'];
                elseif ExcludeNeuronWithReversedOdorSelectivity==2
                   TitleName=[TitleName '-ExcSam-DelayReversedNeu'];
                elseif ExcludeNeuronWithReversedOdorSelectivity==3
                   TitleName=[TitleName '-ExcAllReversedNeu'];      
                elseif ExcludeNeuronWithReversedOdorSelectivity==4
                   TitleName=[TitleName '-OnlyWithAllReversedNeu'];                  
                end
                disp(['----- ' TitleName '-----'])                              
                poolobj = gcp('nocreate'); % If no pool, do not create new one.
                if isempty(poolobj)
                    myCluster=parcluster('local'); myCluster.NumWorkers=WorkerNum; parpool(myCluster,WorkerNum)
                end
                %p = gcp(parpool('local',20));
                %delete(gcp)
                %% Step 1.  Construct raw data
                disp(['-----Step 1 Construct raw data Total Neuron Number-' num2str(length(TargetNeuronID)) '-----'])
                %Construct the raw trial matrix    
                binned_data=cell(1,TotalSingleUnitNum);
                stimulus_ID=cell(1,TotalSingleUnitNum);
                AllNeuronTrialNum=zeros(3,TotalSingleUnitNum);                
                for iNeuron=1:TotalSingleUnitNum% go through each units
                    tempNeuronID=TargetNeuronID(iNeuron);
                    [TrialIndex,temp_stimulus_ID,tempbinned_data,TrialIndex1,TrialIndex2] =ConstructNDTSingleNeuForDecoding...
                        (DecodingForSamTestDecisionTrialType,tempTotalUnitSplitData,tempNeuronID,IsLaserTrial...
                        ,IsCorrectOrErrorOrAllTrials,bin_width,step_size,MeanTrialLength,Decodingclassifier,PairOrNonPairTrials);
                    stimulus_ID{1,iNeuron}=temp_stimulus_ID;
                    binned_data{1,iNeuron}=tempbinned_data;
                    AllNeuronTrialNum(:,iNeuron)=[length(TrialIndex);length(TrialIndex1);length(TrialIndex2)];
                end
                NeuNumWithEnoughTrial=length(find(AllNeuronTrialNum(2,:)>=num_cv_splits&AllNeuronTrialNum(3,:)>=num_cv_splits));
                disp(['-----Neuron Number With Enough Trial-' num2str(NeuNumWithEnoughTrial) '->=' num2str(num_cv_splits) '-----'])      

                %ds.create_simultaneously_recorded_populations = 1;
                %if ds.create_simultaneously_recorded_populations ==1
                   %TitleName =[TitleName  '-SimulRec'];
                  % disp(['----- ' TitleName '-----'])
                  %[stimulus_ID,binned_data]=ExtractNDTSameTrialNumForEachNeuron(stimulus_ID,binned_data,num_cv_splits*num_times_to_repeat_each_label_per_cv_split);
                %end                
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
                % optionally can specify particular sites/neurons to use
                ds.sites_to_use = find_sites_with_k_label_repetitions(stimulus_ID, num_cv_splits);
                if num_neuron_ForDecoding>length(ds.sites_to_use)
                    num_neuron_ForDecoding=length(ds.sites_to_use)-1;
                end
                PoolSize=length(ds.sites_to_use);
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
%                 disp(datetime)
                % run the decoding analysis  run_cv_decoding
                the_cross_validator.display_progress.zero_one_loss=0;
                the_cross_validator.display_progress.resample_run_time=0;
                for idx = 1:NullDistributionNum
                    f(idx) = parfeval(@the_cross_validator.run_cv_decoding,1);%run_cv_decoding the_cross_validator
                end
                for iNullDis = 1:NullDistributionNum
                    [~,DECODING_RESULTS] = fetchNext(f);  % Collect the results as they become available.
                    save([TitleName '-' GroupID '-' num2str(GroupNum) '-' num2str(iNullDis)], 'DECODING_RESULTS','-v7.3');
                    if iNullDis <NullDistributionNum
                        clear DECODING_RESULTS
                    end
                end
%                 disp(datetime)
                save([TitleName '-' GroupID '-' num2str(num_neuron_ForDecoding) '-All Parameters'],'DECODING_RESULTS','binned_data'...
                    ,'stimulus_ID','DecodingForSamTestDecisionTrialType','IsShffleDecoding','num_resample_runs','num_cv_splits'...
                    ,'num_neuron_ForDecoding','TitleName','Classifier','bin_width','step_size','ds','the_cross_validator','OdorMN'...
                    ,'DelayMN','ResponseMN','WaterMN','ITIMN','IsCorrectOrErrorOrAllTrials','PoolSize','StartTime'...
                    ,'IsSustainedOdorSelectiveNeuron','TargetNeuronIDWithSpecificSigBin','AddSustainedNeuronWithSigBinNum','AllNeuronTrialNum'...
                    ,'NeuronIndexInEachTrainingDay','MiceBasedPerformance','ExcludeNeuronWithReversedOdorSelectivity','NeuNumWithEnoughTrial','-v7.3');
            end
        end
    end
    disp([Filename 'Computing End'])
end