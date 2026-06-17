function [RandomlyPicked_stimulus_ID,RandomlyPicked_binned_data]=ExtractNDTSameTrialNumForEachNeuron(stimulus_ID,binned_data,num_trial_ForEachCondition)

%%
RandomlyPicked_stimulus_ID=cell(size(stimulus_ID));
RandomlyPicked_binned_data=cell(size(stimulus_ID));
for iNeuron=1:length(stimulus_ID)%go through each neuron
    temp_stimulus_ID=stimulus_ID{iNeuron};
    
    Sample1TrialID=find(temp_stimulus_ID==1);
    Sample2TrialID=find(temp_stimulus_ID==2);
    tempPickTrialID=[Sample1TrialID(1:num_trial_ForEachCondition);Sample2TrialID(1:num_trial_ForEachCondition)];    
    
    RandomlyPicked_stimulus_ID{iNeuron}=temp_stimulus_ID(tempPickTrialID);
    RandomlyPicked_binned_data{iNeuron}=binned_data{iNeuron}(tempPickTrialID,:);
end

