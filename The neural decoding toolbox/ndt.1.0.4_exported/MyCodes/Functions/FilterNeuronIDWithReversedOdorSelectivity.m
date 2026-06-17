function [NeuronIDWithReversedOdorSelectivity,NonSelectiveNeuID,SampleDelayReversedSelectivityNeuID,DelaySigBinNum]...
    =FilterNeuronIDWithReversedOdorSelectivity(tempTotalUnitSplitData,TimeGain,OdorMN,DelayMN)

TotalSingleUnitNum=length(tempTotalUnitSplitData.UnitID);
DelayBinSize=1;%define the non-overlap bin size to analize the delay period odor selectivity
DelayStepSize=1;
% DelayBinNum=(4+OdorMN+DelayMN-DelayBinSize)/DelayStepSize+1;
DelayBinID=(4+OdorMN+1-DelayBinSize)/DelayStepSize+1:(4+OdorMN+DelayMN-DelayBinSize)/DelayStepSize+1;

DelaySigBinNum=zeros(TotalSingleUnitNum,1);
AllUnitOdorSelectivity=struct('NLIsSignificant',[],'NLOdorSelectivityIndex',[],'NLPValue',[]);
for iNeuron=1:TotalSingleUnitNum%go through each unit
    
    SequentialAllSP=tempTotalUnitSplitData.AllSequentialAllSP{iNeuron};
    TrialsJudgement=tempTotalUnitSplitData.TrialsJudgement{iNeuron}(1:size(SequentialAllSP,2),:);
    UniqueSample1=unique(TrialsJudgement(:,2));
    ATrialIndex= TrialsJudgement(:,2)==UniqueSample1(1);
    BTrialIndex= TrialsJudgement(:,2)==UniqueSample1(2);
    ATrials=SequentialAllSP(:,ATrialIndex);
    BTrials=SequentialAllSP(:,BTrialIndex);
    
    [TempOdorSelectivity]=SecondBasedRankSumTest(ATrials,BTrials,TimeGain,-4,DelayMN+1,DelayBinSize,DelayStepSize,1);
    
    AllUnitOdorSelectivity.NLIsSignificant=[AllUnitOdorSelectivity.NLIsSignificant;TempOdorSelectivity(3,:)];
    AllUnitOdorSelectivity.NLOdorSelectivityIndex=[AllUnitOdorSelectivity.NLOdorSelectivityIndex;TempOdorSelectivity(2,:)];
    AllUnitOdorSelectivity.NLPValue=[AllUnitOdorSelectivity.NLPValue;TempOdorSelectivity(1,:)];
    
    DelaySigBinNum(iNeuron)=sum(TempOdorSelectivity(3,DelayBinID));
end
%%
NeuronIDWithReversedOdorSelectivity=IdentifyDelayReversedSelectiveNeuron(DelaySigBinNum,AllUnitOdorSelectivity,DelayBinID);
NonSelectiveNeuID=find(DelaySigBinNum==0);
%% get the neuron index with sample-delay reversed odor selectivity
SampleBinOdorSelectivity=[AllUnitOdorSelectivity.NLOdorSelectivityIndex(:,5) AllUnitOdorSelectivity.NLIsSignificant(:,5)];
DelayTimeLampsedOdorSelectivity=AllUnitOdorSelectivity.NLOdorSelectivityIndex(:,DelayBinID);
DelayTimeLampsedIsSigOdorSelectivity=AllUnitOdorSelectivity.NLIsSignificant(:,DelayBinID);

DelaySigNeuID=find(DelaySigBinNum>0);
SampleSigNeuID=find(SampleBinOdorSelectivity(:,2)>0);
BothSampleDelaySelectivveNeuID=intersect(DelaySigNeuID,SampleSigNeuID);

SampleDelayReversedSelectivityNeuID=[];
for iNeuron=1:length(BothSampleDelaySelectivveNeuID)
    tempNeuronIndex=BothSampleDelaySelectivveNeuID(iNeuron);
    tempNeuSampleOdorSelectivity=SampleBinOdorSelectivity(tempNeuronIndex,1);
    tempNeuDelayOdorSelectivity=DelayTimeLampsedOdorSelectivity(tempNeuronIndex,:);   
    
    tempNeuronSigBinID=find(DelayTimeLampsedIsSigOdorSelectivity(tempNeuronIndex,:)==1);    
    for iDelayBin=1:length(tempNeuronSigBinID)        
        tempDelayBinOdorSelectivity=tempNeuDelayOdorSelectivity(tempNeuronSigBinID(iDelayBin));
        if tempNeuSampleOdorSelectivity*tempDelayBinOdorSelectivity<0
            SampleDelayReversedSelectivityNeuID=[SampleDelayReversedSelectivityNeuID;tempNeuronIndex];
        end        
    end    
end
SampleDelayReversedSelectivityNeuID=unique(SampleDelayReversedSelectivityNeuID);