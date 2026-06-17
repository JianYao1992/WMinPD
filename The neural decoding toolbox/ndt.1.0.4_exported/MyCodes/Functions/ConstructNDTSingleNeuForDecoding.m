function [TrialIndex,temp_stimulus_ID,tempbinned_data,TrialIndex1,TrialIndex2]=ConstructNDTSingleNeuForDecoding...
    (DecodingForSamTestDecisionTrialType,tempTotalUnitSplitData,tempNeuronID,IsLaserTrial,IsCorrectOrErrorOrAllTrials...
    ,bin_width,step_size,MeanTrialLength,Decodingclassifier,PairOrNonPairTrials)

SequentialAllSP=tempTotalUnitSplitData.AllSequentialAllSP{tempNeuronID};
TrialsJudgement=tempTotalUnitSplitData.TrialsJudgement{tempNeuronID}(1:size(SequentialAllSP,2),:);
TrialLaserDelay=tempTotalUnitSplitData.TrialLaserDelay{tempNeuronID}(1:size(SequentialAllSP,2),:);

%% get the target trial index according to the identity of the first odorant
[temp_stimulus_ID,TrialIndex,TrialIndex1,TrialIndex2]= GetNDTTrialID(DecodingForSamTestDecisionTrialType...
    ,TrialsJudgement,TrialLaserDelay,IsLaserTrial,IsCorrectOrErrorOrAllTrials,PairOrNonPairTrials);

%% construct binned data for each neuron
tempbinned_data=ConstructBinnedDataForNDT(SequentialAllSP,TrialIndex,bin_width,step_size,MeanTrialLength,Decodingclassifier);
