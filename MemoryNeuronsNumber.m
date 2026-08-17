clear; clc; close all;


Region = {'mPFC','aAIC'};
% homedir = 'G:\NoLaserinODPA';
homedir = 'G:\LaserActivationOnOffinODPA\Training';
if contains(homedir,'ActivationOnOff')
    Group = {'laseroff','laseron'};
    SessionBasedMemoryUnitsNumber = struct('mPFC',struct('laseroff',[],'laseron',[]),'aAIC',struct('laseroff',[],'laseron',[]));
else
    Group = {'Healthy','PDModel'};
end
for iGroup = 1:numel(Group)
    if contains(homedir,'ActivationOnOff')
        TarDir = homedir;
        fprintf('Loading units information of LaserOnOff group\n');
        load(fullfile(TarDir,'UnitsInformation_LaserOnOff.mat'),'UnitsInformation');
    else
        TarDir = fullfile(homedir,Group{iGroup},'Training');
        fprintf('Loading units information of %s group\n',Group{iGroup});
        load(fullfile(TarDir,sprintf('UnitsInformation_%s.mat',Group{iGroup})),'UnitsInformation');
    end
    for iReg = 1:numel(Region)
        fprintf('Get %s memory neurons number of %s group\n',Region{iReg},Group{iGroup});
        if contains(homedir,'ActivationOnOff')
            load(fullfile(TarDir,'SortedMemUnitsID_LaserOnOff.mat'),'SortedMemUnitsID');
            SortedMemUnitsID = SortedMemUnitsID.(Group{iGroup}).(Region{iReg});
        else
            load(fullfile(TarDir,sprintf('SortedMemUnitsID_%s_%s.mat',Region{iReg},Group{iGroup})),'SortedMemUnitsID');
        end
        MemUnitsOrigin = UnitsInformation(SortedMemUnitsID,1:2);
        UniqueMouse = unique(UnitsInformation(:,1));
        Day = UnitsInformation(:,2);
        Day = cellfun(@(x) x(end),Day,'UniformOutput',false);
        UniqueDay = unique(Day);
        [UniqueMouse,UniqueDay] = meshgrid(UniqueMouse,UniqueDay);
        if contains(homedir,'ActivationOnOff')
            SessionBasedMemoryUnitsNumber.(Region{iReg}).(Group{iGroup}) = horzcat(UniqueMouse(:),UniqueDay(:));
            MemUnitsNum = [];
            for iSess = 1:size(SessionBasedMemoryUnitsNumber.(Region{iReg}).(Group{iGroup}),1)
                tempMouseID = SessionBasedMemoryUnitsNumber.(Region{iReg}).(Group{iGroup}){iSess,1};
                tempDayID = SessionBasedMemoryUnitsNumber.(Region{iReg}).(Group{iGroup}){iSess,2};
                IsIntheSession = cellfun(@(x,y) strcmp(x,tempMouseID) & contains(y,tempDayID),MemUnitsOrigin(:,1),MemUnitsOrigin(:,2),'UniformOutput',true);
                MemUnitsNum = [MemUnitsNum; nnz(IsIntheSession)];
            end
            SessionBasedMemoryUnitsNumber.(Region{iReg}).(Group{iGroup}) = [SessionBasedMemoryUnitsNumber.(Region{iReg}).(Group{iGroup}) mat2cell(MemUnitsNum,ones(1,numel(MemUnitsNum)),1)];
        else
            SessionBasedMemoryUnitsNumber = horzcat(UniqueMouse(:),UniqueDay(:));
            MemUnitsNum = [];
            for iSess = 1:size(SessionBasedMemoryUnitsNumber,1)
                tempMouseID = SessionBasedMemoryUnitsNumber{iSess,1};
                tempDayID = SessionBasedMemoryUnitsNumber{iSess,2};
                IsIntheSession = cellfun(@(x,y) strcmp(x,tempMouseID) & contains(y,tempDayID),MemUnitsOrigin(:,1),MemUnitsOrigin(:,2),'UniformOutput',true);
                MemUnitsNum = [MemUnitsNum; nnz(IsIntheSession)];
            end
            SessionBasedMemoryUnitsNumber = [SessionBasedMemoryUnitsNumber mat2cell(MemUnitsNum,ones(1,numel(MemUnitsNum)),1)];
        end
        if ~contains(homedir,'ActivationOnOff')
            fprintf('******Saving %s memory neurons number of %s group******\n',Region{iReg},Group{iGroup});
            save(fullfile(TarDir,sprintf('%sMemoryUnitsNumber_%s.mat',Region{iReg},Group{iGroup})),'SessionBasedMemoryUnitsNumber','-v7.3');
        end
    end
end
if contains(homedir,'ActivationOnOff')
    fprintf('******Saving memory neurons number of LaserOnOff group******\n');
    save(fullfile(TarDir,'MemoryUnitsNumber_LaserOnOff.mat'),'SessionBasedMemoryUnitsNumber','-v7.3');
end