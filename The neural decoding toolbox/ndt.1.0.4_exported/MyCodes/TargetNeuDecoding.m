%the code was used to calculate the decoding efficiency with the Neural Decoding Toolbox
% addpath(genpath('/home/qcheng/personaldata/uploaddata/Decoding'))%ION computing center
clear;clc;close all

TargetBrainID='AI';%define the brain area for summary
UnitSummaryFile=dir(['*' TargetBrainID '-DPA-AllUnitsSummary*.mat']);
for iFile=[1 2 3]%go through each group of data
    Filename=UnitSummaryFile(iFile).name(1:end-4);
    disp(Filename)
    disp(datetime)
    %TargetDayID=[{[1]};{[2]};{[3]};{[4 5]}];%;{3};{[4]};{[5]};{[6]};{[7]}define the group days used to perform decoding analysis
    TargetDayID=[{[1 2 3 4 5]}]; %
    WorkerNum=17;

    for ExcludeNeuronWithReversedOdorSelectivity=0;% ChR-602-82=520;NL:704-55=649; NpHR:451-26=425;    
        
        AddSustainedNeuronWithSigBinNum=[1 2];%add selective neurons to non-selective pools with target bin number having sustained 1 second odor selectivity  during delay period
        CellType=1;% 1 for all neurons, 2 for pyramidal neurons, 3 for interneurons
        PairOrNonPairTrials=3;%1 for pairing trials, 2 for non-pairing trials,3 for all trials
        IsCorrectOrErrorOrAllTrials=3;%1 for correct trials, 2 for error trials , 3 for all trials        
        Decodingclassifier=1;%:3%11 for max_correlation_coefficient_CL£¬2 for poisson_naive_bayes_CL£¬3 for support vector machine        
        IsShffleDecoding=0;
        IsCalculateTCTDecodingResults=1;
        DecodingForSamTestDecisionTrialType=1;% Decoding for 1-sample odor,2-test odor, 3-decision(FC or CR in nonpair trials), 4-trial type(Pair-Nonpair)
        IsNormalizedData=1;
        %For reversed selectivity neuron number in each day
        %ChR: Day1-176-27; Day2-145-19; Day3-130-13; Day4-5-185-23;  82 in total
        % NL: Day1-113-10; Day2-129-13; Day3-134-8;  Day4-5-328-24;; 55
        %NpHR: Day1-110-4; Day2-100-7;  Day3=101-5;  Day4-5-140-10;  26
                
        %1 for equal in specific bin
        %   ChR2 group    [214 176,101,58,39,14],602 in total  [1 2 3]484
        %no-laser group   [276 197,129,61,28,13],704 in total
        %   NpHR group    [209 124, 60,36,15,7] ,451 in total  [1 2 3]409
        %after Bonferroni correction
        %   ChR2 group    [296 222(153 69),29,22(16 6)],569 in total
        %no-laser group   [423 228(148 80),31,22(13 9)],704 in total
        %   NpHR group    [300 124(82  42),19, 8(4  4)] ,451 in total    
        NonSelectiveNeuNum=0;  TargetSelectiveNeuNum=120;
        num_neuron_ForDecoding=NonSelectiveNeuNum+TargetSelectiveNeuNum;
        if ExcludeNeuronWithReversedOdorSelectivity==1&&length(TargetDayID)>1
           num_neuron_ForDecoding=100;
        elseif ExcludeNeuronWithReversedOdorSelectivity==2&&length(TargetDayID)>1
           num_neuron_ForDecoding=200;        
        end
        if IsCorrectOrErrorOrAllTrials==2
            num_neuron_ForDecoding=240;%NpHR-254, NL-244£¬ ChR2-302
        end
        if CellType==2%2 for pyramidal neurons
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
            NullDistributionNum= 50;
            num_resample_runs = 1;%50 for normal decoding, 10 for null-distribution decoding
            step_size = 100;
        else
            step_size = 100;
            if IsShffleDecoding==1
                GroupNum=1;
                NullDistributionNum = 100;
                num_resample_runs = 10;
            else
                GroupNum=2;
                NullDistributionNum =700;
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
                    ,num_neuron_ForDecoding,0,bin_width,IsNormalizedData,GroupID...
                    ,[],TrainingDayID,IsCorrectOrErrorOrAllTrials,0,IsCalculateTCTDecodingResults,step_size...
                    ,AddSustainedNeuronWithSigBinNum,CellType,PairOrNonPairTrials);
                if ExcludeNeuronWithReversedOdorSelectivity==1
                   TitleName=[TitleName '-ExcReversedNeu'];
                elseif ExcludeNeuronWithReversedOdorSelectivity==2
                   TitleName=[TitleName '-WithReversedNeu'];
                end
                disp(['----- ' TitleName '-----'])
                %% add neurons with sustained odor selectivty to no selective neurons
                disp('-----Pre-processing the odor selectivity for each neuron -----')
                [TargetNeuronID,IsSustainedOdorSelectiveNeuron,DelaySigBinNum,TargetNeuronIDWithSpecificSigBin...
                    ,NeuronNumWithDiffSig1SecondBin]=ConstructNeuronIDWithSpecificSustainedNeu(tempTotalUnitSplitData,TimeGain,DelayMN...
                    ,DecodingForSamTestDecisionTrialType,AddSustainedNeuronWithSigBinNum,IsLaserTrial,IsCorrectOrErrorOrAllTrials,PairOrNonPairTrials);
                NonSelectiveNeuID=find(DelaySigBinNum==0);
                disp(['-----Non-selective neuron number-' num2str(length(NonSelectiveNeuID)) '---RequiredNum=-' num2str(NonSelectiveNeuNum) '-----'])
                TargetSelecNeuID=setdiff(TargetNeuronID,NonSelectiveNeuID);                
                disp(['-----Target sig neuron number-' num2str(length(TargetSelecNeuID)) '---RequiredNum=-' num2str(TargetSelectiveNeuNum) '-----'])    
                
                TargetNeuronID1=NonSelectiveNeuID;
                TargetNeuronID2=TargetSelecNeuID;
                %% Step 1.  Construct raw data
                disp(['-----Step 1 Construct raw data Total Neuron Number-' num2str(length(TargetNeuronID)) '-----'])
                %Construct the raw trial matrix
                TotalSingleUnitNum=length(TargetNeuronID1);                
                if NonSelectiveNeuNum>0
                    binned_data1=cell(1,TotalSingleUnitNum);
                    stimulus_ID1=cell(1,TotalSingleUnitNum);
                    for iNeuron=1:TotalSingleUnitNum% go through each non-selective neuron
                        tempNeuronID=TargetNeuronID1(iNeuron);
                        [TrialIndex,temp_stimulus_ID,tempbinned_data] =ConstructNDTSingleNeuForDecoding(DecodingForSamTestDecisionTrialType...
                            ,tempTotalUnitSplitData,tempNeuronID,IsLaserTrial,IsCorrectOrErrorOrAllTrials,bin_width,step_size,MeanTrialLength...
                            ,Decodingclassifier,PairOrNonPairTrials);
                        stimulus_ID1{1,iNeuron}=temp_stimulus_ID;
                        binned_data1{1,iNeuron}=tempbinned_data;
                    end
                else
                    binned_data1=[];
                    stimulus_ID1=[];
                end
                %% construct raw data for target selecitve neurons                  
                if TargetSelectiveNeuNum>0
                    binned_data2=cell(1,length(TargetNeuronID2));
                    stimulus_ID2=cell(1,length(TargetNeuronID2));
                    for iNeuron=1:length(TargetNeuronID2)% go through each non-selective neuron
                        tempNeuronID=TargetNeuronID2(iNeuron);
                        [TrialIndex,temp_stimulus_ID,tempbinned_data] =ConstructNDTSingleNeuForDecoding(DecodingForSamTestDecisionTrialType,tempTotalUnitSplitData...
                            ,tempNeuronID,IsLaserTrial,IsCorrectOrErrorOrAllTrials,bin_width,step_size,MeanTrialLength,Decodingclassifier,PairOrNonPairTrials);
                        stimulus_ID2{1,iNeuron}=temp_stimulus_ID;
                        binned_data2{1,iNeuron}=tempbinned_data;
                    end
                else
                    binned_data2=[];
                    stimulus_ID2=[];
                end
                poolobj = gcp('nocreate'); % If no pool, do not create new one.
                if isempty(poolobj)
                    myCluster=parcluster('local'); myCluster.NumWorkers=WorkerNum; parpool(myCluster,WorkerNum)
                end
                %delete(gcp)   
                %% Step 5 :randomly split the neuron pool
                disp(['-----Step 5 Construct the the_cross_validator with target neuron pools-' num2str(NullDistributionNum) '-----'])
                AllSplit_the_cross_validator=cell(1,NullDistributionNum);
                for i = 1:NullDistributionNum                 
                    temp1=randperm(length(binned_data1));
                    temp2=randperm(length(binned_data2));                    
                    binned_data=[binned_data1(temp1(1:NonSelectiveNeuNum)) binned_data2(temp2(1:TargetSelectiveNeuNum))];
                    stimulus_ID=[stimulus_ID1(temp1(1:NonSelectiveNeuNum)) stimulus_ID2(temp2(1:TargetSelectiveNeuNum))];
                    
                    [~,the_cross_validator1]=ConstructNDTDecodingParameters(binned_data, stimulus_ID, num_cv_splits,bin_width...
                        ,num_times_to_repeat_each_label_per_cv_split,IsShffleDecoding,num_neuron_ForDecoding,StartTime,step_size...
                        ,MeanTrialLength,NotComputeLastSecondNum,Decodingclassifier,IsCalculateTCTDecodingResults,num_resample_runs);                     
                    AllSplit_the_cross_validator{1,i}=the_cross_validator1;
                    clear the_cross_validator1
                end
                %% Step 6.  Run the decoding analysis
                disp('-----Step 6 Run the decoding analysis-----')
                % disp(datetime)
                % run the decoding analysis  run_cv_decoding                
                for idx = 1:NullDistributionNum
                    the_cross_validator=AllSplit_the_cross_validator{1,idx};
                    f(idx) = parfeval(@the_cross_validator.run_cv_decoding,1);
                end
                for iNullDis = 1:NullDistributionNum
                    [~,DECODING_RESULTS] = fetchNext(f);  % Collect the results as they become available.
                    save([TitleName '-' GroupID '-' num2str(NonSelectiveNeuNum) '-' num2str(TargetSelectiveNeuNum)...
                        '-' num2str(GroupNum) '-' num2str(iNullDis)], 'DECODING_RESULTS','-v7.3');
                    if iNullDis <NullDistributionNum
                        clear DECODING_RESULTS
                    end
                end
%                 disp(datetime)
                save([TitleName '-' GroupID '-' num2str(num_neuron_ForDecoding) '-' num2str(NonSelectiveNeuNum) '-' num2str(TargetSelectiveNeuNum) '-All Parameters']...
                    ,'DECODING_RESULTS','binned_data1','binned_data2','stimulus_ID1','stimulus_ID2','DecodingForSamTestDecisionTrialType'...
                    ,'IsShffleDecoding','num_resample_runs','num_cv_splits','num_neuron_ForDecoding','TitleName','Classifier','bin_width'...
                    ,'step_size','AllSplit_the_cross_validator','OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','IsCorrectOrErrorOrAllTrials'...
                    ,'StartTime','IsSustainedOdorSelectiveNeuron','TargetNeuronIDWithSpecificSigBin','AddSustainedNeuronWithSigBinNum'...
                    ,'NeuronIndexInEachTrainingDay','MiceBasedPerformance','ExcludeNeuronWithReversedOdorSelectivity',...
                    'NonSelectiveNeuNum','TargetSelectiveNeuNum','-v7.3');
            end
        end
    end
    disp([Filename 'Computing End'])
end