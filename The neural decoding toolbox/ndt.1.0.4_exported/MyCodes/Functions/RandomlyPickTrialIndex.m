function [RandomPickedTrialIndex1,RandomPickedTrialIndex2]=RandomlyPickTrialIndex(TrialIndex1,TrialIndex2,num_trial_ForEachCondition)

if length(TrialIndex1)>=num_trial_ForEachCondition&&length(TrialIndex2)>=num_trial_ForEachCondition    
    temp=randperm(length(TrialIndex1));
    RandomPickedTrialIndex1=sort(TrialIndex1(temp(1:num_trial_ForEachCondition)));
    
    temp2=randperm(length(TrialIndex2));
    RandomPickedTrialIndex2=sort(TrialIndex2(temp2(1:num_trial_ForEachCondition)));        
else
    RandomPickedTrialIndex1=[];
    RandomPickedTrialIndex2=[];
end

