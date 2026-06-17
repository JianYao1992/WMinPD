function [temp_stimulus_ID,TrialIndex,TrialIndex1,TrialIndex2]= GetNDTTrialID(DecodingForSamTestDecisionTrialType...
    ,TrialsJudgement,TrialLaserDelay,IsLaserTrial,IsCorrectOrErrorOrAllTrials,PairOrNonPairTrials...
    ,SequentialAllSP,BaselinePer,SPlen,TimeGain)

if nargin==6
    SequentialAllSP=[];
    BaselinePer=[];
    SPlen=[];
    TimeGain=[];
end

if PairOrNonPairTrials==1%pairing trials
    TargetTrialID=find(TrialsJudgement(:,end-1)<3);
elseif PairOrNonPairTrials==2%Non-pairing trials
    TargetTrialID=find(TrialsJudgement(:,end-1)>=3);
else%all trials
    TargetTrialID=1:size(TrialsJudgement,1);
end
if DecodingForSamTestDecisionTrialType==1
    TrialType=unique(TrialsJudgement(:,2));%&(TrialsJudgement(:,4)==3|TrialsJudgement(:,4)==4)
    if IsCorrectOrErrorOrAllTrials==1
        TrialIndex1=find(TrialLaserDelay(:,2)==IsLaserTrial&TrialsJudgement(:,2)==TrialType(1)&(TrialsJudgement(:,end-1)==1|TrialsJudgement(:,end-1)==4));
        TrialIndex2=find(TrialLaserDelay(:,2)==IsLaserTrial&TrialsJudgement(:,2)==TrialType(2)&(TrialsJudgement(:,end-1)==1|TrialsJudgement(:,end-1)==4));
    elseif IsCorrectOrErrorOrAllTrials==2
        TrialIndex1=find(TrialLaserDelay(:,2)==IsLaserTrial&TrialsJudgement(:,2)==TrialType(1)&(TrialsJudgement(:,end-1)==2|TrialsJudgement(:,end-1)==3));
        TrialIndex2=find(TrialLaserDelay(:,2)==IsLaserTrial&TrialsJudgement(:,2)==TrialType(2)&(TrialsJudgement(:,end-1)==2|TrialsJudgement(:,end-1)==3));
    elseif IsCorrectOrErrorOrAllTrials==3
        TrialIndex1=find(TrialsJudgement(:,2)==TrialType(1));%TrialLaserDelay(:,2)==IsLaserTrial&
        TrialIndex2=find(TrialsJudgement(:,2)==TrialType(2));%TrialLaserDelay(:,2)==IsLaserTrial&
    end
    TrialIndex1=intersect(TrialIndex1,TargetTrialID);
    TrialIndex2=intersect(TrialIndex2,TargetTrialID);
    %% get the 40 trials with largest baseline firing rate 
    if nargin>6
        Rule1CrossTrialMeanFR=CalculateCrossTrialMeanFR(SequentialAllSP(:,TrialIndex1),BaselinePer,SPlen,TimeGain);
        [~,ID]=sortrows(Rule1CrossTrialMeanFR);
        TrialIndex1(ID(1:20))=[];
        Rule2CrossTrialMeanFR=CalculateCrossTrialMeanFR(SequentialAllSP(:,TrialIndex2),BaselinePer,SPlen,TimeGain);
        [~,ID2]=sortrows(Rule2CrossTrialMeanFR);
        TrialIndex2(ID2(1:20))=[];
    end
    TrialIndex=[TrialIndex1;TrialIndex2];
    temp_stimulus_ID=TrialsJudgement(TrialIndex,2);
elseif DecodingForSamTestDecisionTrialType==2 %decoding for test odor
    TrialType=unique(TrialsJudgement(:,3));
    TrialIndex1=find(TrialLaserDelay(:,2)==IsLaserTrial&TrialsJudgement(:,3)==TrialType(1));
    TrialIndex2=find(TrialLaserDelay(:,2)==IsLaserTrial&TrialsJudgement(:,3)==TrialType(2));
    TrialIndex1=intersect(TrialIndex1,TargetTrialID);
    TrialIndex2=intersect(TrialIndex2,TargetTrialID);
    
    TrialIndex=[TrialIndex1;TrialIndex2];
    temp_stimulus_ID=TrialsJudgement(TrialIndex,3);
elseif DecodingForSamTestDecisionTrialType==3% Decoding for Decision %noly for non-pairing trials
    TrialIndex= TrialsJudgement(:,end)>2;
    TrialType=unique(TrialsJudgement(TrialIndex,end-1));
    TrialIndex1=find(TrialLaserDelay(:,2)==IsLaserTrial&TrialsJudgement(:,end-1)==TrialType(1));
    TrialIndex2=find(TrialLaserDelay(:,2)==IsLaserTrial&TrialsJudgement(:,end-1)==TrialType(2));
    %     [RandomPickedTrialIndex1,RandomPickedTrialIndex2]=RandomlyPickTrialIndex(TrialIndex1,TrialIndex2,num_trial_ForEachCondition);
    %     TrialIndex=[RandomPickedTrialIndex1;RandomPickedTrialIndex2];
    
    TrialIndex=[TrialIndex1;TrialIndex2];
    temp_stimulus_ID=TrialsJudgement(TrialIndex,end-1);
elseif DecodingForSamTestDecisionTrialType==4% pairing or non-pairing trials
    TrialIndex1=find(TrialLaserDelay(:,2)==IsLaserTrial&(TrialsJudgement(:,end-1)==1|TrialsJudgement(:,end-1)==2));
    TrialIndex2=find(TrialLaserDelay(:,2)==IsLaserTrial&(TrialsJudgement(:,end-1)==3|TrialsJudgement(:,end-1)==4));
    
    TrialIndex=[TrialIndex1;TrialIndex2];
    temp_stimulus_ID=TrialsJudgement(TrialIndex,end-1);
    temp_stimulus_ID(temp_stimulus_ID==2)=1;
    temp_stimulus_ID(temp_stimulus_ID==3|temp_stimulus_ID==4)=2;
end