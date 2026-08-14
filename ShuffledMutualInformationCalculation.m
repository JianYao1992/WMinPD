function ShuffledMutualInformation = ShuffledMutualInformationCalculation(AllTrialFR,TrialNuminFirstKindOfTrial,TimeGain)

ShuffledMutualInformation = [];
rng('default');
ShuffledOrder = randperm(size(AllTrialFR,1));
ShuffledFR_S1 = AllTrialFR(ShuffledOrder(1:TrialNuminFirstKindOfTrial),:);
ShuffledFR_S2 = AllTrialFR(ShuffledOrder((1+TrialNuminFirstKindOfTrial):end),:);
for iSec = 1:floor(size(ShuffledFR_S1,2)/TimeGain)
    tempMeanFR_S1 = mean(ShuffledFR_S1(:,2+(iSec-1)*TimeGain:1+iSec*TimeGain),2);
    tempMeanFR_S2 = mean(ShuffledFR_S2(:,2+(iSec-1)*TimeGain:1+iSec*TimeGain),2);
    tempMI = calcMI(tempMeanFR_S1,tempMeanFR_S2);
    ShuffledMutualInformation = [ShuffledMutualInformation tempMI];   
end

