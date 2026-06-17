function  [MiceID,TargetTrainingDay]=GetTrainingDay(TotalUnitSplitData)

AllUnitDataID=TotalUnitSplitData.DataID;
Positions = zeros(length(AllUnitDataID),1);
T = regexpi(AllUnitDataID, 'day');
E = cellfun(@isempty, T);
Positions(~E) = cellfun(@(IDX) IDX(1), T(~E));
Positions=num2cell(Positions);

DayID=cellfun(@(x,y) x(1:y+3),AllUnitDataID,Positions,'UniformOutput',0);
TargetTrainingDay=unique(DayID);

DayIndex=strfind(TargetTrainingDay, '201');
MiceID=cellfun(@(x,y) x(7:y-2),TargetTrainingDay,DayIndex,'UniformOutput',0);
MiceID=unique(MiceID);

TrainingDayForEachMouse=cell(length(MiceID),2);
for iMouse=1:length(MiceID)
    tempMouse=MiceID{iMouse};
    T = regexpi(TargetTrainingDay, tempMouse);
    E = ~cellfun(@isempty, T);
    TargetMouseTrainingDay=TargetTrainingDay(E);
    
    DayIndex=strfind(TargetMouseTrainingDay, '201');
    tempMiceID=cellfun(@(x,y) x(7:y-2),TargetMouseTrainingDay,DayIndex,'UniformOutput',0);  
    IsTargetMouse=cell2mat(cellfun(@(x,y) isequal(x,y),tempMiceID,repmat({tempMouse},size(tempMiceID)),'uniformoutput',0));  
    TargetMouseTrainingDay=TargetMouseTrainingDay(IsTargetMouse); 
    
    TrainingDayForEachMouse{iMouse,1}=length(TargetMouseTrainingDay);
    TrainingDayForEachMouse{iMouse,2}=TargetMouseTrainingDay;
end
MiceID=[MiceID TrainingDayForEachMouse];