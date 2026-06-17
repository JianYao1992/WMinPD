%the code was used to calculate the decoding efficiency with the Neural Decoding Toolbox
addpath(genpath('D:\CQ\Matlab codes'))
%CQDecodingOld NDTDecoding CompareTwoDecodingResultsPermTestDiff CompareMultipleDecodingResults
%PlotNDTDecodingResultsPermutationTest PlotTCTDecodingPermutationTest NDTDecodingAnaAccordingToPerformance
%CrossDayROCAna  AllUnitsOdorSelectivityAna PopulationHeatMap LaserEfeectsOnNDTDecodingAna
clear;clc;close all;
TargetBrainID='AI';%define the brain area for summary
IsShffleDecoding=0;
Decodingclassifier=1;%11 for max_correlation_coefficient_CL£¬2 for poisson_naive_bayes_CL£¬3 for support vector machine
DecodingForSamTestDecisionTrialType=1;% Decoding for 1-sample odor,2-test odor, 3-decision(FC or CR in nonpair trials), 4-trial type(Pair-Nonpair)
IsCalculateTCTDecodingResults=0;
% DeleteUnstableNeuronID1=[[1 11 49 91 104 109 120 137 144 148 158 177 191 201 209 210 229 248 263 267 289 300 308 322 345 358]...
% [388 401 414 427 439 440 456 465 482 497 499 528 529 530 551 575 581 601 607 617 620 624 630 633]];%ChR2 group in day1-2-3-4-5 index
% DeleteUnstableNeuronID2=[[10:32 42 69 88 98 115 127 136 138 143 145 154 166 171:181 188 189 193 195 226 241 267 273 280 290 301]...
% [309 314 323 331 339 350 369 382 400 422 452 483 499 500 514 515 521 538 557 587 588 606 613 623 664 673 675 676 686 692 693 698 699]...
% [723 728 732 733 734 743 744 749]];%No Laser group in day1-2-3-4-5 index
% DeleteUnstableNeuronID3=[[49 50 53 57 58 66 71 80 81 82 112 113 114 135 167 169 171 175 182 204 224 271 280 284 288 295 296 301 309]...
% [317 323 330 343 366 369 371 392 401 412 419 437 439 450 466]];%NpHR group in day1-2-3-4-5 index
% DeleteUnstableNeuronID=[{DeleteUnstableNeuronID1};{DeleteUnstableNeuronID2};{DeleteUnstableNeuronID3}];

CellType=1;% 1 for all neurons, 2 for pyramidal neurons, 3 for interneurons
AddSustainedNeuronWithSigBinNum=[6];%add selective neurons to non-selective pools with target bin number having sustained 1 second odor selectivity  during delay period
%1 for equal in specific bin
%   ChR2 group    [214 176,101,58,39,14],602 in total
%no-laser group   [276 197,129,61,28,13],704 in total
%   NpHR group    [209 124, 60,36,15,7] ,451 in total
%2 for equal/larger than target sig bin num no-laser group[257,149,73,31,13], laser group [143,67,34,12,3]
%3 for equal in specific significant bin number no-laser group [178 108 76 42 18 13],PL-AITerminal laser group [171 76 33 22 9 3]
%for all neurons, no laser group have [213,133,84,46,24,13],PL-AITerminal laser group [250£¬117£¬57£¬37£¬11£¬5]
IsCorrectOrErrorOrAllTrials=3;%1 for correct trials, 2 for error trials , 3 for all trials
IsExcludeNLNeurons=0;%1 for exclude neurons in no laser group for well-training phase
IsNormalizedData=1;
PickUpNeuronsWithOdorSelectivity=0;
num_neuron_ForDecoding=540; %464-NoLaser group, 450 for ChR2 group, 381 for NpHR Group
%For all neurons NL ChR NpHR [967 641 551], PC [782 501 452], FSI [185 140 99]
if min(AddSustainedNeuronWithSigBinNum)>=0&&max(AddSustainedNeuronWithSigBinNum)<=5
    num_neuron_ForDecoding=210;%170 neurons for both groups laser group 314-143=171; no laser group=435-257=178;
end
if IsCorrectOrErrorOrAllTrials==2
    num_neuron_ForDecoding=230;%NpHR-254, NL-244£¬ ChR2-302
end
bin_width=500;%define the bin width for each sliding window  200
if IsCorrectOrErrorOrAllTrials==1||IsCorrectOrErrorOrAllTrials==3
    num_cv_splits =40; %the trial number for each stimulus condition used to perform the decoding analysis; test times
elseif IsCorrectOrErrorOrAllTrials==2
    num_cv_splits =20; %the trial number for each stimulus condition used to perform the decoding analysis; test times
end
if IsCorrectOrErrorOrAllTrials==1||IsCorrectOrErrorOrAllTrials==2
    num_times_to_repeat_each_label_per_cv_split= 1;
elseif IsCorrectOrErrorOrAllTrials==3
    num_times_to_repeat_each_label_per_cv_split= 2;
end
if IsCalculateTCTDecodingResults==1
    GroupNum=1;
    NullDistributionNum =1;
    num_resample_runs = 50;%50 for normal decoding, 10 for null-distribution decoding
    PlotFigure=1;
    step_size = 100;
else
    step_size = 100;
    if IsShffleDecoding==1
        GroupNum=4;
        NullDistributionNum = 20;
        num_resample_runs = 10;
        PlotFigure=0;
    else
        GroupNum=1;
        NullDistributionNum =1;
        num_resample_runs = 50;%50 for normal decoding, 10 for null-distribution decoding
        PlotFigure=1;
    end
end
StartTime=1;%start from StartTime second after to 4s baseline(which means 4-StartTime before the sample odor)
NotComputeLastSecondNum=6+2;

%Cross day neuron number
%   ChR2 group    [169 132 125 110  66],602 in total
%no-laser group   [113 129,134,166,162],704 in total
%   NpHR group    [110 100,101, 66, 75],451 in total

TargetMiceID=[];
% NaiveMiceOrExperiencedMice=3;%1 for naive mice, 2 for learned mice, else using all mice
% if NaiveMiceOrExperiencedMice==1%110 neurons in total
%     TargetMiceID=[{'PL-NpHR-AI-10'};{'PL-NpHR-AI-12'};{'PLNPHR-AITerminal-6'}];
% elseif NaiveMiceOrExperiencedMice==2%204 neurons in total
%     TargetMiceID=[{'PFCNpHR-AIterminal-7'};{'PFCNpHR-AIterminal-8'};{'PLNPHR-AITerminal-4'}];
% end
% Naive mice {'PL-NpHR-AI-10'};{'PL-NpHR-AI-12'};{'PLNPHR-AITerminal-6'}
% learning DPA before laser suppression:{'PFCNpHR-AIterminal-7'};{'PFCNpHR-AIterminal-8'};{'PLNPHR-AITerminal-4'}
% if NaiveMiceOrExperiencedMice<=2%for NpHR laser group
%     num_neuron_ForDecoding=100;
% end
%%
UnitSummaryFile=dir(['*' TargetBrainID '-DPA-AllUnitsSummary*.mat']);
if size(UnitSummaryFile,1)~=0
    load(UnitSummaryFile.name);
    Filename=UnitSummaryFile.name;
    GroupID='-NL';
    IsChR=regexpi(Filename,'ChR');
    if ~isempty(IsChR)
        GroupID='-ChR';
    end
    IsNpHR=regexpi(Filename,'NpHR');
    if ~isempty(IsNpHR)
        GroupID='-NpHR';
    end
    tempTotalUnitSplitData=TotalUnitSplitData;
    TimeGain=tempTotalUnitSplitData.TimeGain{1}(1);
    Path=pwd;
    TrialLaserDelay=TotalUnitSplitData.TrialLaserDelay{1};
    LaserPhase=unique(TrialLaserDelay(:,2));%2 for laser in block design
    IsLaserGroup=max(LaserPhase);%0 no laser condition, 1 for laser condition
    %% excluded unstable neuron index
    if exist('DeleteUnstableNeuronID','var')
        disp(['---- Excluded Unstable Neurons-' num2str(length(DeleteUnstableNeuronID)) '----'])
        tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,DeleteUnstableNeuronID);
    end
    %%
    if CellType>1%identify the cell type with the waveform,1 for all neurons, 2 for pyramidal neurons, 3 for interneurons
        AllWaveForm=TotalUnitSplitData.WaveForm;
        Threshold=350;%threshold seperate fast spiking interneuron and pyramidal neurons
        [AllPeakTroughDuration,FSIID,PCID]=IdentifyCellTypeBasedOnWaveform(AllWaveForm,Threshold);    
        if CellType==2
            tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,PCID);
        elseif CellType==3
            tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,FSIID);
        end
    end
    %% Excluded the neurons according to the performance
    %get the training day ID
    [MiceID,TargetTrainingDay]=GetTrainingDay(tempTotalUnitSplitData);
    %get the performance and neuron ID for each training day
    DayBasedPerformanceNeuron=DayBasedPerAndNeuronInfo(tempTotalUnitSplitData,TargetTrainingDay);
    %get all the neuron index in the traget training day
    [~,MiceBasedPerformance]=GetNeuronIndexInEachTrainingDay(DayBasedPerformanceNeuron,MiceID);
    %extract neurons from pre-specfied mice
    if ~isempty(TargetMiceID)
        disp(['---- Extract neuron for target mice group-' num2str(NaiveMiceOrExperiencedMice) '----'])
        TargetNeuronID=ExtractNeuronIDForTargetMice(MiceBasedPerformance,TargetMiceID);
        tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,TargetNeuronID);
    end
    if IsExcludeNLNeurons&&IsLaserGroup==0%no laser group has more neurons in well-training phase
        disp('---- Excluded No Laser Well-Trained Neurons ----')
        ExcludedTrainingDayPerformanCriterion=100;% if 100, do not excluded any data
        [TargetTrainingDay,ExcludedTrainingDay,ExcludedNeuronIndex]=...
            ExcludedTrainingDayAccordingToPer(tempTotalUnitSplitData,TargetTrainingDay,ExcludedTrainingDayPerformanCriterion);
        tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,ExcludedNeuronIndex);
    end
    %% pick up the neurons with significant delay period sample odor selectivity
    if PickUpNeuronsWithOdorSelectivity==1&&DecodingForSamTestDecisionTrialType==1
        [tempTotalUnitSplitData,NeuronIndexWithDelayOdorSelectivity,AllUnitOdorSelectivity]=...
            PickUpSignificantSelectiveNeurons(tempTotalUnitSplitData,DelayMN,TimeGain);
        disp('---Sample Odor selective neuron number/Total Neuron---')
        disp(['---' num2str(num_neuron_ForDecoding) '/' num2str(size(AllUnitOdorSelectivity.NLIsSignificant,1)) '---'])
    end
    %%
    SPlen=min(vertcat(tempTotalUnitSplitData.ShortSPlen{:}));
    MeanTrialLength=SPlen*1/TimeGain;
    TotalSingleUnitNum=length(tempTotalUnitSplitData.AllSequentialAllSP);
    TrialLaserDelay=tempTotalUnitSplitData.TrialLaserDelay{1};
    LaserPhase=unique(tempTotalUnitSplitData.TrialLaserDelay{1}(:,2));%2 for laser in block design
    IsLaserGroup=max(LaserPhase);%0 no laser condition, 1 for laser condition
    for iIsLaserTrial=1:length(LaserPhase)%go through laser or no laser trial
        disp('---Current Loop Number/Total Loop Number---')
        CurrentLoopNum=iIsLaserTrial;
        disp(['---' num2str(CurrentLoopNum) '/' num2str(length(LaserPhase)) '---'])
        disp(['---- GroupNum-' num2str(GroupNum) '-TotalNullDistributionNum-' num2str(NullDistributionNum) '----'] )
        IsLaserTrial=LaserPhase(iIsLaserTrial);
        [TitleName,Classifier]=ConstructNDTDecodingTitle(TargetBrainID,Decodingclassifier,DecodingForSamTestDecisionTrialType...
            ,IsShffleDecoding,num_resample_runs,num_cv_splits,num_times_to_repeat_each_label_per_cv_split,IsLaserGroup...
            ,num_neuron_ForDecoding,PickUpNeuronsWithOdorSelectivity,bin_width,IsNormalizedData,IsLaserTrial...
            ,[],[],IsCorrectOrErrorOrAllTrials,IsExcludeNLNeurons,IsCalculateTCTDecodingResults,step_size...
            ,AddSustainedNeuronWithSigBinNum,CellType);
        if ~isempty(IsChR)&&IsLaserGroup==1
            TitleName=regexprep(TitleName,'NPHR',GroupID,'ignorecase');
        end
%         if NaiveMiceOrExperiencedMice==1
%             TitleName=[TitleName '-NaiveMice'];
%         elseif NaiveMiceOrExperiencedMice==2
%             TitleName=[TitleName '-LearnedMice'];
%         end
        disp(['----- ' TitleName '-----'])
        %% add neurons with sustained odor selectivty to no selective neurons
        TimeLampsedOdorSelectivity=zeros(TotalSingleUnitNum,DelayMN);
        IsSustainedOdorSelectiveNeuron=zeros(TotalSingleUnitNum,5);
        NonSelectiveNeuronID=zeros(TotalSingleUnitNum,1);
        TargetNeuronIDWithSpecificSigBin=[];
        if min(AddSustainedNeuronWithSigBinNum)>=0&&max(AddSustainedNeuronWithSigBinNum)<=5
            disp('-----Pre-processing the odor selectivity for each neuron -----')
            [TargetNeuronID,IsSustainedOdorSelectiveNeuron,SigBinNum,TargetNeuronIDWithSpecificSigBin...
                ,NeuronNumWithDiffSig1SecondBin]=ConstructNeuronIDWithSpecificSustainedNeu(tempTotalUnitSplitData,TimeGain,DelayMN...
                ,DecodingForSamTestDecisionTrialType,AddSustainedNeuronWithSigBinNum,IsLaserTrial,IsCorrectOrErrorOrAllTrials);
        else
            TargetNeuronID=1:TotalSingleUnitNum;
        end
        poolobj = gcp('nocreate'); % If no pool, do not create new one.
        if isempty(poolobj)
            myCluster=parcluster('local'); myCluster.NumWorkers=16; parpool(myCluster,16)
        end
        %p = gcp(parpool('local',20));
        %delete(gcp)
        %% Step 1.  Construct raw data
        disp(['-----Step 1 Construct raw data Total Neuron Number-' num2str(length(TargetNeuronID)) '-----'])
        %Construct the raw trial matrix
        TotalSingleUnitNum=length(TargetNeuronID);
        binned_data=cell(1,TotalSingleUnitNum);
        stimulus_ID=cell(1,TotalSingleUnitNum);
        AllNeuronTrialNum=zeros(1,TotalSingleUnitNum);         
        for iNeuron=1:TotalSingleUnitNum% go through each units
            tempNeuronID=TargetNeuronID(iNeuron);
            [TrialIndex,temp_stimulus_ID,tempbinned_data] =ConstructNDTSingleNeuForDecoding(DecodingForSamTestDecisionTrialType,tempTotalUnitSplitData...
                ,tempNeuronID,IsLaserTrial,IsCorrectOrErrorOrAllTrials,bin_width,step_size,MeanTrialLength,Decodingclassifier);
            AllNeuronTrialNum(iNeuron)=length(TrialIndex);
            stimulus_ID{1,iNeuron}=temp_stimulus_ID;
            binned_data{1,iNeuron}=tempbinned_data;
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
        % optionally can specify particular sites/neurons to use
        ds.sites_to_use = find_sites_with_k_label_repetitions(stimulus_ID, num_cv_splits);
        if num_neuron_ForDecoding>=length(ds.sites_to_use)
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
        % run the decoding analysis  run_cv_decoding
        the_cross_validator.display_progress.zero_one_loss=0;
        the_cross_validator.display_progress.resample_run_time=0;
        Path=pwd;
        for iNullDis=1:NullDistributionNum
            if IsShffleDecoding==1
                disp(['---Shuffled decoding-' num2str(iNullDis) '---'])
            else
                disp(['---Decoding-' num2str(iNullDis) '---'])
            end
            DECODING_RESULTS = the_cross_validator.run_cv_decoding; %run_cv_decoding
            %decoding_results [num_resample_runs x num_cv_splits x num_training_times x num_test_times]
            save([TitleName '-' num2str(GroupNum) '-' num2str(iNullDis)], 'DECODING_RESULTS','-v7.3');
        end
        TitleName=[TitleName '-Group-' num2str(GroupNum)];
        save(TitleName,'DECODING_RESULTS','-v7.3')
        %% Step 7.  Plot the basic results
        disp('-----Step 7 Plot the basic results -----')
        disp(['----- ' TitleName '-----'])
        if IsShffleDecoding~=1&&PlotFigure==1
            plot_obj.p_values=[];
            result_names{1} = TitleName;
            plot_obj = plot_standard_results_object(result_names);
            plot_obj.errorbar_file_names={TitleName};
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
            title(TitleName(5:end-8))
            text(2.5,80,['NeuronNum=' num2str(num_neuron_ForDecoding)],'fontsize',12,'color',[0 0 1])
            saveas(gcf,TitleName ,'fig')%
            saveas(gcf,TitleName ,'png')%
            close all
        end
        %% Step 8.  Plot the TCT matrix
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
            plot_obj.color_result_range=[40 100];
            plot_obj.plot_results;  % plot_results  plot_standard_results_TCT_object
            axis([-0.5 8 -0.5 8])
            title(TitleName(5:end-8))
            saveas(gcf,[TitleName '-TCT'] ,'fig')%
            saveas(gcf,[TitleName '-TCT'] ,'png')%
            close all
        end
        cd(Path)
        save([TitleName '-'  num2str(num_neuron_ForDecoding) '-All Parameters'],'DECODING_RESULTS','binned_data','stimulus_ID'...
            ,'DecodingForSamTestDecisionTrialType','IsShffleDecoding','num_resample_runs','num_cv_splits','TitleName'...
            ,'num_neuron_ForDecoding','TitleName','Classifier','bin_width','step_size','UnitSummaryFile'...
            ,'OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','IsCorrectOrErrorOrAllTrials','PoolSize','StartTime'...
            ,'IsExcludeNLNeurons','IsSustainedOdorSelectiveNeuron','TargetMiceID','MiceBasedPerformance'...
            ,'TargetNeuronIDWithSpecificSigBin','AddSustainedNeuronWithSigBinNum','-v7.3');
    end
end