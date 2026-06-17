function DayBasedPerformance=DayBasedPerAndNeuronInfo(TotalUnitSplitData,TargetTrainingDay)

% TargetTrainingDayID=+~cellfun(@isvector,TotalUnitSplitData.FirstOdor);
% TargetTrainingDayIndex=find(TargetTrainingDayID==1);

DayBasedPerformance=cell(length(TargetTrainingDay),7);
for iTrainingDay=1:length(TargetTrainingDay)   
    
    Positions = zeros(length(TotalUnitSplitData.DataID),1);
    T = strfind(TotalUnitSplitData.DataID, TargetTrainingDay{iTrainingDay});
    E = cellfun(@isempty, T);
    Positions(~E) = cellfun(@(IDX) IDX(1), T(~E));
    
    NeuronIndexInTargetDay=find(Positions>0);    
    TrialsJudgement=TotalUnitSplitData.TrialsJudgement{min(NeuronIndexInTargetDay)};
    [~,Data,~]=GetResultsFromTrials(TrialsJudgement,20);
    
    [~,SubDays,~]=unique(TotalUnitSplitData.DataID(NeuronIndexInTargetDay));    
    SingleUnitTetrodeList=TotalUnitSplitData.SingleUnitTetrodeList(SubDays+(min(NeuronIndexInTargetDay)-1));    
    SingleUnitTetrodeList=vertcat(SingleUnitTetrodeList{:});    
    
    Performance=length(find(TrialsJudgement(:,end-1)==1|TrialsJudgement(:,end-1)==4))/size(TrialsJudgement,1)*100;
    DayBasedPerformance{iTrainingDay,2}=Performance;
    DayBasedPerformance{iTrainingDay,1}=TotalUnitSplitData.DataID{min(NeuronIndexInTargetDay)};
    DayBasedPerformance{iTrainingDay,3}=length(NeuronIndexInTargetDay);
    DayBasedPerformance{iTrainingDay,4}=NeuronIndexInTargetDay;
    DayBasedPerformance{iTrainingDay,5}=Data; %(:,end) 
    DayBasedPerformance{iTrainingDay,6}=TrialsJudgement;  
    DayBasedPerformance{iTrainingDay,7}=SingleUnitTetrodeList;  
end