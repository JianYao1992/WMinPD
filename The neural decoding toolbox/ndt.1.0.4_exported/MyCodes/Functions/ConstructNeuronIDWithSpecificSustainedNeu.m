function [TargetNeuronID,IsSustainedOdorSelectiveNeuron,DelaySigBinNum,TargetNeuronIDWithSpecificSigBin...
    ,NeuronNumWithDiffSig1SecondBin]=ConstructNeuronIDWithSpecificSustainedNeu(tempTotalUnitSplitData,TimeGain,DelayMN...
    ,DecodingForSamTestDecisionTrialType,AddSustainedNeuronWithSigBinNum,IsLaserTrial,IsCorrectOrErrorOrAllTrials,PairOrNonPairTrials)

TotalSingleUnitNum=length(tempTotalUnitSplitData.AllSequentialAllSP);

IsSustainedOdorSelectiveNeuron=zeros(TotalSingleUnitNum,DelayMN);
NonSelectiveNeuronID=zeros(TotalSingleUnitNum,1);
for iNeuron=1:TotalSingleUnitNum% go through each units
    SequentialAllSP=tempTotalUnitSplitData.AllSequentialAllSP{iNeuron};
    TrialsJudgement=tempTotalUnitSplitData.TrialsJudgement{iNeuron}(1:size(SequentialAllSP,2),:);
    TrialLaserDelay=tempTotalUnitSplitData.TrialLaserDelay{iNeuron}(1:size(SequentialAllSP,2),:);
    [~,~,TrialIndex1,TrialIndex2]= GetNDTTrialID(DecodingForSamTestDecisionTrialType...
        ,TrialsJudgement,TrialLaserDelay,IsLaserTrial,IsCorrectOrErrorOrAllTrials,PairOrNonPairTrials);
    TempOdorSelectivity=SecondBasedRankSumTest(SequentialAllSP(:,TrialIndex1),SequentialAllSP(:,TrialIndex2),TimeGain,1,DelayMN+1);
    IsSustainedOdorSelectiveNeuron(iNeuron,:)=TempOdorSelectivity(3,:);
    if sum(IsSustainedOdorSelectiveNeuron(iNeuron,:))==0%non selective neuron
        NonSelectiveNeuronID(iNeuron)=1;
    end
end
DelaySigBinNum=sum(IsSustainedOdorSelectiveNeuron,2);
disp(['-----AddSustainedNeuWithSigBinNum-' num2str(AddSustainedNeuronWithSigBinNum) '-----'])
NonSelectiveNeuID=find(DelaySigBinNum==0);
TargetNeuronIDWithSpecificSigBin=[];
for i=1:length(AddSustainedNeuronWithSigBinNum)
    TargetNeuronIDWithSpecificSigBin=[TargetNeuronIDWithSpecificSigBin;find(DelaySigBinNum==AddSustainedNeuronWithSigBinNum(i))];
end
TargetNeuronID=[TargetNeuronIDWithSpecificSigBin;NonSelectiveNeuID];
TargetNeuronID=unique(TargetNeuronID);

NeuronNumWithDiffSig1SecondBin=zeros(1,6);
for i=0:5
    NeuronNumWithDiffSig1SecondBin(i+1)=length(find(DelaySigBinNum==i));
end