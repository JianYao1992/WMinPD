function [RandPickedFR_Hit, RandPickedFR_Miss, RandPickedFR_FA, RandPickedFR_CR] = ExtractSpecTrialNumForEachNeuron(FR, TrialID, TrialNumForEachCondition, IsShuffled, IsConsiderCorrectError)
% INPUTS:
%   FR                      - Cell array of binned firing rates for neurons (1×N unit)
%   TrialID                 - Cell array of trial indices for different conditions
%   TrialNumForEachCondition- Number of trials to select (empty = use all trials)
%   IsShuffled              - 1 = shuffle trial indices; 0 = use original indices
%   IsConsiderCorrectError  - 1 = split trials by Hit/Miss/FA/CR; 0 = split by S1/S2
% OUTPUTS:
%   RandPickedFR_Hit/Miss/FA/CR - Cell arrays of selected firing rates for each trial type

% Initialize output cell arrays
nUnit = size(FR, 2);
RandPickedFR_Hit = cell(1, nUnit);
RandPickedFR_Miss = cell(1, nUnit);
RandPickedFR_FA  = cell(1, nUnit);
RandPickedFR_CR  = cell(1, nUnit);

% Traverse each neuron unit for trial extraction/shuffling
for iUnit = 1:nUnit
    if IsConsiderCorrectError == 0
        [idx1, idx2] = getS1S2Index(TrialID, iUnit); % get S1/S2 trial indices
        
        % shuffle S1/S2 indices
        if IsShuffled == 1
            allIdx = [idx1; idx2];
            shufIdx = randperm(length(allIdx));
            idx1 = allIdx(shufIdx(1:length(idx1)));
            idx2 = allIdx(shufIdx(length(idx1)+1:end));
        end
        
        % randomly select trials (specify num or use all)
        RandPickedFR_Hit{1,iUnit} = selectTrials(FR{iUnit}, idx1, TrialNumForEachCondition);
        RandPickedFR_CR{1,iUnit}  = selectTrials(FR{iUnit}, idx2, TrialNumForEachCondition);

    else
        idxHit = TrialID{1,iUnit};  
        idxMiss = TrialID{2,iUnit}; 
        idxFa = TrialID{3,iUnit};  
        idxCr = TrialID{4,iUnit};   
        
        % shuffle FA/CR indices if required
        if IsShuffled == 1
            allFaCr = [idxFa; idxCr];
            shufFaCr = randperm(length(allFaCr));
            idxFa = allFaCr(shufFaCr(1:length(idxFa)));
            idxCr = allFaCr(shufFaCr(length(idxFa)+1:end));
        end
        
        % Randomly select trials for each type
        RandPickedFR_Hit{1,iUnit} = selectTrials(FR{iUnit}, idxHit, TrialNumForEachCondition);
        RandPickedFR_Miss{1,iUnit} = selectTrials(FR{iUnit}, idxMiss, TrialNumForEachCondition);
        RandPickedFR_FA{1,iUnit}  = selectTrials(FR{iUnit}, idxFa, TrialNumForEachCondition);
        RandPickedFR_CR{1,iUnit}  = selectTrials(FR{iUnit}, idxCr, TrialNumForEachCondition);
    end
end

end

%% -------------------------------------------------------------
function [idxS1, idxS2] = getS1S2Index(TrialID, iUnit)
% Get S1/S2 trial indices by TrialID dimension (2 or 4 rows)
if size(TrialID, 1) == 2
    idxS1 = TrialID{1,iUnit};
    idxS2 = TrialID{2,iUnit};
else
    idxS1 = vertcat(TrialID{1,iUnit}, TrialID{2,iUnit});
    idxS2 = vertcat(TrialID{3,iUnit}, TrialID{4,iUnit});
end
end

function frSelected = selectTrials(fr, trialIdx, selNum)
% Input: fr (nTrial×nBins); trialIdx = trial indices; selNum = number of trials to select
shufIdx = randperm(length(trialIdx));
if ~isempty(selNum)
    shufIdx = shufIdx(1:selNum); 
end
frSelected = fr(trialIdx(shufIdx), :);
end