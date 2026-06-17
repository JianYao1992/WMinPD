%the code was used to calculate the decoding efficiency with the Neural Decoding Toolbox
addpath(genpath('/home/qcheng/personaldata/uploaddata/Decoding'))%ION computing center
clear;clc;close all

TargetBrainID='AI';%define the brain area for summary
UnitSummaryFile=dir(['*' TargetBrainID '-DPA-AllUnitsSummary*.mat']);
for iFile=[1]%:size(UnitSummaryFile,1)%go through each group of data
    Filename=UnitSummaryFile(iFile).name(1:end-4);
    disp(Filename)
%     disp(datetime)
    %TargetDayID=[{[1]};{[2]};{[3]};{[4 5]}];%;{3};{[4]};{[5]};{[6]};{[7]}define the group days used to perform decoding analysis
    TargetDayID=[{[1 2 3 4 5]}]; %
    WorkerNum=10;

    for ExcludeNeuronWithReversedOdorSelectivity=0% ChR-602-82=520;NL:704-55=649; NpHR:451-26=425;
        
    	CellType=1;% 1 for all neurons, 2 for pyramidal neurons, 3 for interneurons
    	AddSustainedNeuronWithSigBinNum=[6];%add selective neurons to non-selective pools with target bin number having sustained 1 second odor selectivity  during delay period
        PairOrNonPairTrials=3;%1 for pairing trials, 2 for non-pairing trials,3 for all trials
        IsCorrectOrErrorOrAllTrials=3;%1 for correct trials, 2 for error trials , 3 for all trials        
        Decodingclassifier=1;%:3%11 for max_correlation_coefficient_CL£¬2 for poisson_naive_bayes_CL£¬3 for support vector machine        
        IsShffleDecoding=0;
        IsCalculateTCTDecodingResults=0;
        DecodingForSamTestDecisionTrialType=1;% Decoding for 1-sample odor,2-test odor, 3-decision(FC or CR in nonpair trials), 4-trial type(Pair-Nonpair)

        %For reversed selectivity neuron number in each day
        %ChR: Day1-176-27; Day2-145-19; Day3-130-13; Day4-5-185-23;  82 in total
        % NL: Day1-113-10; Day2-129-13; Day3-134-8;  Day4-5-328-24;; 55
        %NpHR: Day1-110-4; Day2-100-7;  Day3=101-5;  Day4-5-140-10;  26
        
        %1 for equal in specific bin
        %   ChR2 group    [214 176,101,58,39,14],602 in total  [1 2 3]484
        %no-laser group   [276 197,129,61,28,13],704 in total
        %   NpHR group    [209 124, 60,36,15,7] ,451 in total  [1 2 3]409
        %2 for equal/larger than target sig bin num no-laser group[257,149,73,31,13], laser group [143,67,34,12,3]
        %3 for equal in specific significant bin number no-laser group [178 108 76 42 18 13],PL-AITerminal laser group [171 76 33 22 9 3]
        % for all neurons, no laser group have [213,133,84,46,24,13],PL-AITerminal laser group [250£¬117£¬57£¬37£¬11£¬5]
        % IsCorrectOrErrorOrAllTrials=3;%1 for correct trials, 2 for error trials , 3 for all trials
        IsExcludeNLNeurons=0;%1 for exclude neurons in no laser group for well-training phase
        IsNormalizedData=1;
        PickUpNeuronsWithOdorSelectivity=0;
        num_neuron_ForDecoding=200; %370 for all and 242 selective neuron for block design 470/227; 210 neurons for error trials; 310 neurons for all trials
        if ExcludeNeuronWithReversedOdorSelectivity==1
           num_neuron_ForDecoding=200;
        elseif ExcludeNeuronWithReversedOdorSelectivity==2
           num_neuron_ForDecoding=200;        
        end
        %For all neurons NL ChR NpHR [967 641 551], PC [782 501 452], FSI [185 140 99]
        if min(AddSustainedNeuronWithSigBinNum)>=0&&max(AddSustainedNeuronWithSigBinNum)<=5
            num_neuron_ForDecoding=200;%the smallest non-selective neuron number is 209 in NpHR group 
        end
        if IsCorrectOrErrorOrAllTrials==2
            num_neuron_ForDecoding=240;%NpHR-254, NL-244£¬ ChR2-302
        end
        if CellType==2%2 for pyramidal ne urons
            num_neuron_ForDecoding=360;
        elseif CellType==3%3 for interneurons
            num_neuron_ForDecoding=80;%95 for three groups
        end
        bin_width=500;%define the bin width for each sliding window  200
        if IsCorrectOrErrorOrAllTrials==1||IsCorrectOrErrorOrAllTrials==3
            num_cv_splits =[40]; %the trial number for each stimulus condition used to perform the decoding analysis; test times  10 20
        elseif IsCorrectOrErrorOrAllTrials==2
            num_cv_splits =[20]; %the trial number for each stimulus condition used to perform the decoding analysis; test times  10 20
        end
        if IsCorrectOrErrorOrAllTrials==1||IsCorrectOrErrorOrAllTrials==2||PairOrNonPairTrials<3
            num_times_to_repeat_each_label_per_cv_split= 1;
        elseif IsCorrectOrErrorOrAllTrials==3
            num_times_to_repeat_each_label_per_cv_split= 2;
        end
        if IsCalculateTCTDecodingResults==1
            GroupNum=1;
            NullDistributionNum= 1000;
            num_resample_runs = 1;%50 for normal decoding, 10 for null-distribution decoding
            step_size = 100;
        else
            step_size = 100;
            if IsShffleDecoding==1
                GroupNum=1;
                NullDistributionNum = 100;
                num_resample_runs = 10;
            else
                GroupNum=1;
                NullDistributionNum =1000;
                num_resample_runs = 1;%50 for normal decoding, 10 for null-distribution decoding
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
            
           %tempTotalUnitSplitData=CombineTotalUnitSplitData(tempTotalUnitSplitData1,tempTotalUnitSplitData2);            
           
            if ExcludeNeuronWithReversedOdorSelectivity==1
                [NeuronIDWithReversedOdorSelectivity,NonSelectiveNeuID]=FilterNeuronIDWithReversedOdorSelectivity(tempTotalUnitSplitData,TimeGain,OdorMN,DelayMN);
                tempTotalUnitSplitData=DelateNeuronsInTotalUnitSplitData(tempTotalUnitSplitData,NeuronIDWithReversedOdorSelectivity);
                disp(['---- Excluded Neurons With reversed odor selectivity-' num2str(length(NeuronIDWithReversedOdorSelectivity)) '----'])
            elseif ExcludeNeuronWithReversedOdorSelectivity==2
                [NeuronIDWithReversedOdorSelectivity,NonSelectiveNeuID]=FilterNeuronIDWithReversedOdorSelectivity(tempTotalUnitSplitData,TimeGain,OdorMN,DelayMN);
                tempTotalUnitSplitData=FilterTotalUnitSplitData(TotalUnitSplitData,[NeuronIDWithReversedOdorSelectivity;NonSelectiveNeuID]);
                disp(['---- Decoding With reversed odor selectivity-' num2str(length(NeuronIDWithReversedOdorSelectivity)) '----'])
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
            %% pick up the neurons with significant delay period sample odor selectivity
            if PickUpNeuronsWithOdorSelectivity==1
                [tempTotalUnitSplitData,NeuronIndexWithDelayOdorSelectivity,AllUnitOdorSelectivity]=...
                    PickUpSignificantSelectiveNeurons(tempTotalUnitSplitData,DelayMN,TimeGain);
                disp('---Sample Odor selective neuron number/Total Neuron---')
                disp(['---' num2str(num_neuron_ForDecoding) '/' num2str(length(tempTotalUnitSplitData.DataID)) '---'])
            end 
            %%
            SPlen=min(vertcat(tempTotalUnitSplitData.ShortSPlen{:}));
            MeanTrialLength=SPlen*1/TimeGain;
            TotalSingleUnitNum=length(tempTotalUnitSplitData.AllSequentialAllSP);
            LaserPhase=unique(tempTotalUnitSplitData.TrialLaserDelay{1}(:,2));%2 for laser in block design
            IsLaserGroup=max(LaserPhase);%0 no laser condition, 1 for laser condition
            for iIsLaserTrial=1:length(LaserPhase)%go through laser or no laser trial
                disp('---Current Loop Number/Total Loop Number---')
                disp(['---' num2str(iIsLaserTrial) '/' num2str(length(LaserPhase)) '---'])
                disp(['---- GroupNum-' num2str(GroupNum) '-TotalNullDistributionNum-' num2str(NullDistributionNum) '----'] )
                IsLaserTrial=LaserPhase(iIsLaserTrial);
                [TitleName,Classifier]=ConstructNDTDecodingTitle('AI',Decodingclassifier,DecodingForSamTestDecisionTrialType...
                    ,IsShffleDecoding,num_resample_runs,num_cv_splits,num_times_to_repeat_each_label_per_cv_split...
                    ,num_neuron_ForDecoding,PickUpNeuronsWithOdorSelectivity,bin_width,IsNormalizedData,GroupID...
                    ,[],TrainingDayID,IsCorrectOrErrorOrAllTrials,IsExcludeNLNeurons,IsCalculateTCTDecodingResults,step_size...
                    ,AddSustainedNeuronWithSigBinNum,CellType,PairOrNonPairTrials);
                if ExcludeNeuronWithReversedOdorSelectivity==1
                   TitleName=[TitleName '-ExcReversedNeu'];
                elseif ExcludeNeuronWithReversedOdorSelectivity==2
                   TitleName=[TitleName '-WithReversedNeu'];
                end
                disp(['----- ' TitleName '-----'])
                %% add neurons with sustained odor selectivty to no selective neurons
                IsSustainedOdorSelectiveNeuron=zeros(TotalSingleUnitNum,5);
                TargetNeuronIDWithSpecificSigBin=[];
                if min(AddSustainedNeuronWithSigBinNum)>=0&&max(AddSustainedNeuronWithSigBinNum)<=5
                    disp('-----Pre-processing the odor selectivity for each neuron -----')
                    [TargetNeuronID,IsSustainedOdorSelectiveNeuron,SigBinNum,TargetNeuronIDWithSpecificSigBin...
                        ,NeuronNumWithDiffSig1SecondBin]=ConstructNeuronIDWithSpecificSustainedNeu(tempTotalUnitSplitData,TimeGain,DelayMN...
                        ,DecodingForSamTestDecisionTrialType,AddSustainedNeuronWithSigBinNum,IsLaserTrial,IsCorrectOrErrorOrAllTrials,PairOrNonPairTrials);
                else
                    TargetNeuronID=1:TotalSingleUnitNum;
                end                
                poolobj = gcp('nocreate'); % If no pool, do not create new one.
                if isempty(poolobj)
                    myCluster=parcluster('local'); myCluster.NumWorkers=WorkerNum; parpool(myCluster,WorkerNum)
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
                        ,tempNeuronID,IsLaserTrial,IsCorrectOrErrorOrAllTrials,bin_width,step_size,MeanTrialLength,Decodingclassifier,PairOrNonPairTrials);
                    AllNeuronTrialNum(iNeuron)=length(TrialIndex);
                    stimulus_ID{1,iNeuron}=temp_stimulus_ID;
                    binned_data{1,iNeuron}=tempbinned_data;
                end    
                %% Step 5 :randomly split the neuron pool
                disp(['-----Step 5 randomly split the neuron pool-' num2str(NullDistributionNum) '-----'])
                AllSplit_the_cross_validator=cell(2,NullDistributionNum);
                if exist('NLNeuNum','var')
                    Group1NeuNum=NLNeuNum;
                elseif exist('Phase1NeuNum','var')
                    Group1NeuNum=Phase1NeuNum;
                end
                for i = 1:NullDistributionNum
                    temp=randperm(length(binned_data));
                    ShuffleSample1=temp(1:Group1NeuNum);
                    ShuffleSample2=temp(Group1NeuNum+1:length(temp));
                    binned_data1=binned_data(ShuffleSample1);
                    binned_data2=binned_data(ShuffleSample2);
                    stimulus_ID1=stimulus_ID(ShuffleSample1);
                    stimulus_ID2=stimulus_ID(ShuffleSample2);
                    
                    [~,the_cross_validator1]=ConstructNDTDecodingParameters(binned_data1, stimulus_ID1, num_cv_splits,bin_width...
                        ,num_times_to_repeat_each_label_per_cv_split,IsShffleDecoding,num_neuron_ForDecoding,StartTime,step_size...
                        ,MeanTrialLength,NotComputeLastSecondNum,Decodingclassifier,IsCalculateTCTDecodingResults,num_resample_runs);
                    [~,the_cross_validator2]=ConstructNDTDecodingParameters(binned_data2, stimulus_ID2, num_cv_splits,bin_width...
                        ,num_times_to_repeat_each_label_per_cv_split,IsShffleDecoding,num_neuron_ForDecoding,StartTime,step_size...
                        ,MeanTrialLength,NotComputeLastSecondNum,Decodingclassifier,IsCalculateTCTDecodingResults,num_resample_runs);
                    
                    AllSplit_the_cross_validator(:,i)=[{the_cross_validator1};{the_cross_validator2}];
                end
                %% Step 6.  Run the decoding analysis
                disp('-----Step 6 Run the decoding analysis-----')
                % disp(datetime)
                % run the decoding analysis  run_cv_decoding                
                for idx = 1:NullDistributionNum                  
                    f(idx) = parfeval(@CrossGroupShuffleDecoding,1,AllSplit_the_cross_validator{1,idx},AllSplit_the_cross_validator{2,idx});                     
                end
                for iNullDis = 1:NullDistributionNum
                    [~,DECODING_RESULTS] = fetchNext(f);  % Collect the results as they become available.
                    DECODING_RESULTS1=DECODING_RESULTS{1};
                    DECODING_RESULTS2=DECODING_RESULTS{2};
                    clear DECODING_RESULTS
                    save([TitleName '-' GroupID '-Phase1-' num2str(GroupNum) '-' num2str(iNullDis)], 'DECODING_RESULTS1','-v7.3');                    
                    save([TitleName '-' GroupID '-Phase3-' num2str(GroupNum) '-' num2str(iNullDis)], 'DECODING_RESULTS2','-v7.3');
                    if iNullDis <NullDistributionNum
                        clear DECODING_RESULTS1 DECODING_RESULTS2
                    end
                end
%                 disp(datetime)
                save([TitleName '-' GroupID '-' num2str(num_neuron_ForDecoding) '-All Parameters'],'DECODING_RESULTS','binned_data'...
                    ,'stimulus_ID','DecodingForSamTestDecisionTrialType','IsShffleDecoding','num_resample_runs','num_cv_splits'...
                    ,'num_neuron_ForDecoding','TitleName','Classifier','ds','the_cross_validator','bin_width','step_size','OdorMN'...
                    ,'DelayMN','ResponseMN','WaterMN','ITIMN','IsCorrectOrErrorOrAllTrials','StartTime','IsExcludeNLNeurons'...
                    ,'IsSustainedOdorSelectiveNeuron','TargetNeuronIDWithSpecificSigBin','AddSustainedNeuronWithSigBinNum'...
                    ,'NeuronIndexInEachTrainingDay','MiceBasedPerformance','ExcludeNeuronWithReversedOdorSelectivity','-v7.3');%
            end
        end
    end
    disp([Filename 'Computing End'])
end