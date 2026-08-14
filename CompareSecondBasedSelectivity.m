%% This code aims to compare specific neurons' sample-coding ability between two groups.

clear; clc; close all;

addpath(genpath('D:\Codes\Function'));

%% Assignment
homedir = 'G:\NoLaserinODPA';
phase = 'Learning phase';
Reg = {'mPFC','aAIC'};
SelecType = 3; % 1: AUC; 2: percent of explained variance (PEV); 3: mutual information
switch SelecType
    case 1
        selectype = 'AUC';
    case 2
        selectype = 'PEV';
    case 3
        selectype = 'MI';
end
if contains(homedir,'ActivationOnOff')
    BaselineLength = 8;
    DelayLength = 6;
    colorset = {[0 125 0]/255,[67 106 178]/255};
else
    BaselineLength = 13;
    DelayLength = 10;
    colorset = {[0 0 0],[0 125 0]/255};
end
SampleOdorLength = 1;
TestOdorLength = 1;
ResponseWindowLength = 1;
FRthreshold = 1;
FAthreshold = 0.0025;

for iReg = 1:numel(Reg)
    tempReg = Reg{iReg};
    %% Obtain perception and memory neurons second-based selectivity
    if contains(homedir,'ActivationOnOff')
        [PercUnitsSelec_group1,MemUnitsSelec_group1,MemUnitsShuffledSelec_group1,AllUnitsSelec_group1] = PerceptionMemoryAllUnitsCodingAbility(homedir,tempReg,FRthreshold,FAthreshold,'laseroff',BaselineLength,SampleOdorLength,SelecType);
        [PercUnitsSelec_group2,MemUnitsSelec_group2,MemUnitsShuffledSelec_group2,AllUnitsSelec_group2] = PerceptionMemoryAllUnitsCodingAbility(homedir,tempReg,FRthreshold,FAthreshold,'laseron',BaselineLength,SampleOdorLength,SelecType);
    else
        [PercUnitsSelec_group1,MemUnitsSelec_group1,MemUnitsShuffledSelec_group1,AllUnitsSelec_group1] = PerceptionMemoryAllUnitsCodingAbility(homedir,tempReg,FRthreshold,FAthreshold,'Healthy',BaselineLength,SampleOdorLength,SelecType);
        [PercUnitsSelec_group2,MemUnitsSelec_group2,MemUnitsShuffledSelec_group2,AllUnitsSelec_group2] = PerceptionMemoryAllUnitsCodingAbility(homedir,tempReg,FRthreshold,FAthreshold,'PDmodel',BaselineLength,SampleOdorLength,SelecType);
    end

    % %% Plot second-based coding ability of perception neurons
    % PercUnitsSelec_group1 = mean(PercUnitsSelec_group1(:,BaselineLen+1:BaselineLen+SampOdorLen),2); % sample-delivery period
    % PercUnitsSelec_group2 = mean(PercUnitsSelec_group2(:,BaselineLen+1:BaselineLen+SampOdorLen),2);
    % PercUnitsSelec_group1(any(isinf(PercUnitsSelec_group1),2),:) = []; % delete neurons with value Inf or -Inf
    % PercUnitsSelec_group2(any(isinf(PercUnitsSelec_group2),2),:) = [];
    % % figure
    % figure('Position',[219 303 550 400]);
    % plotBarAndError(colorset{1},1.1,PercUnitsSelec_group1,1); % bar and errorbar
    % arrayfun(@(x) plot(1.1+randn()*0.08,PercUnitsSelec_group1(x),'o','MarkerSize',1,'MarkerFaceColor',colorset{1},'MarkerEdgeColor','none'),1:numel(PercUnitsSelec_group1)); % scatter
    % hold on
    % plotBarAndError(colorset{2},1.9,PercUnitsSelec_group2,1);
    % arrayfun(@(x) plot(1.9+randn()*0.08,PercUnitsSelec_group2(x),'o','MarkerSize',1,'MarkerFaceColor',colorset{2},'MarkerEdgeColor','none'),1:numel(PercUnitsSelec_group2));
    % set(gca,'XTick',[1.1 1.9],'XTickLabel',num2cell(1:2),'xlim',[0.6 2.4]);
    % box off;
    % % % ranksum test
    % % Pvalue = ranksum(PercUnitsSelec_group1,PercUnitsSelec_group2);
    % % anova1 test
    % [~,tbl,~] = anova1(vertcat(PercUnitsSelec_group1,PercUnitsSelec_group2),vertcat(ones(numel(PercUnitsSelec_group1),1),2*ones(numel(PercUnitsSelec_group2),1)),'off');
    % title(sprintf('NUMgroup1 = %d, NUMgroup2 = %d, pvalue = %d',numel(PercUnitsSelec_group1),numel(PercUnitsSelec_group2),tbl{2,6}));
    % set(gcf,'Renderer','Painter'); saveas(gcf,fullfile(homedir,sprintf('Compare %s of %s perception neurons_%s',selectype,Reg,phase)),'fig'); close all;
    % save(fullfile(homedir,sprintf('P value for compairing %s of %s perception neurons_%s',selectype,Reg,phase)),'tbl','-v7.3');

    %% Plot second-based coding ability of memory neurons
    % real selectivity
    MemUnitsSelec_group1 = MemUnitsSelec_group1(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength); % whole delay
    MemUnitsSelec_group2 = MemUnitsSelec_group2(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength);
    InfIDinSelec_group1 = any(isnan(MemUnitsSelec_group1),2);
    InfIDinSelec_group2 = any(isnan(MemUnitsSelec_group2),2);

    % shuffled selectivity
    MemUnitsShuffledSelec_group1 = MemUnitsShuffledSelec_group1(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength); % whole delay
    MemUnitsShuffledSelec_group2 = MemUnitsShuffledSelec_group2(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength);
    InfIDinShuffledSelec_group1 = any(isnan(MemUnitsShuffledSelec_group1),2);
    InfIDinShuffledSelec_group2 = any(isnan(MemUnitsShuffledSelec_group2),2);

    % Inf ID
    InfID_group1 = InfIDinSelec_group1 | InfIDinShuffledSelec_group1;
    InfID_group2 = InfIDinSelec_group2 | InfIDinShuffledSelec_group2;

    % real selectivity and shuffled selectivity of residual memory neurons
    MemUnitsSelec_group1(InfID_group1,:) = [];
    MemUnitsSelec_group2(InfID_group2,:) = [];
    MemUnitsShuffledSelec_group1(InfID_group1,:) = [];
    MemUnitsShuffledSelec_group2(InfID_group2,:) = [];

    % converted to cell format
    MemUnitsSelec_group1 = mat2cell(MemUnitsSelec_group1,size(MemUnitsSelec_group1,1),ones(1,size(MemUnitsSelec_group1,2)));
    MemUnitsSelec_group2 = mat2cell(MemUnitsSelec_group2,size(MemUnitsSelec_group2,1),ones(1,size(MemUnitsSelec_group2,2)));
    MemUnitsShuffledSelec_group1 = mat2cell(MemUnitsShuffledSelec_group1,size(MemUnitsShuffledSelec_group1,1),ones(1,size(MemUnitsShuffledSelec_group1,2)));
    MemUnitsShuffledSelec_group2 = mat2cell(MemUnitsShuffledSelec_group2,size(MemUnitsShuffledSelec_group2,1),ones(1,size(MemUnitsShuffledSelec_group2,2)));

    % plot figure
    figure('Position',[219 303 550 400]);
    PlotCellData(MemUnitsSelec_group1,colorset{1},2,'-','o',colorset{1},colorset{1},10,-0.5);
    PlotCellData(MemUnitsSelec_group2,colorset{2},2,'-','o',colorset{2},colorset{2},10,-0.5);
    PlotCellData(MemUnitsShuffledSelec_group1,colorset{1},2,'--','o',colorset{1},colorset{1},10,-0.5);
    PlotCellData(MemUnitsShuffledSelec_group2,colorset{2},2,'--','o',colorset{2},colorset{2},10,-0.5);
    % PlotEventCurve(SampleOdorLength,DelayLength,TestOdorLength,ResponseWindowLength,2,1);
    SetXYaxisProperty(0,1,SampleOdorLength+DelayLength+TestOdorLength+ResponseWindowLength,0,DelayLength,'Time in delay (s)',0,0.1,1,0,1,['Population averaged ' selectype],16,18); box off;
    title(['NUMgroup1 = ' num2str(numel(MemUnitsSelec_group1{1})) '; NUMgroup2 = ' num2str(numel(MemUnitsSelec_group2{1}))]);
    % Tw-ANOVA-md
    Ps = GetDataMatrixForMixedRepeatedAnova({MemUnitsSelec_group1,MemUnitsSelec_group2},fullfile(homedir,strcat('DelayBinBased',tempReg,['MemoryUnits' selectype '_'],phase)));
    set(gcf,'Renderer','Painter'); saveas(gcf,fullfile(homedir,sprintf('Compare delay bin-based %s memory neurons %s_%s',tempReg,selectype,phase)),'fig'); close all;

    % %% Plot second-based coding ability of all neurons
    % AllUnitsSelec_group1 = AllUnitsSelec_group1(:,BaselineLen:BaselineLen+SampOdorLen+DelayLen); % baseline (1 s before sample onset) to whole delay
    % AllUnitsSelec_group2 = AllUnitsSelec_group2(:,BaselineLen:BaselineLen+SampOdorLen+DelayLen);
    % AllUnitsSelec_group1(any(isinf(AllUnitsSelec_group1),2),:) = []; % delete neurons with value Inf or -Inf
    % AllUnitsSelec_group2(any(isinf(AllUnitsSelec_group2),2),:) = [];
    % AllUnitsSelec_group1 = mat2cell(AllUnitsSelec_group1,size(AllUnitsSelec_group1,1),ones(1,size(AllUnitsSelec_group1,2))); % converted to cell format
    % AllUnitsSelec_group2 = mat2cell(AllUnitsSelec_group2,size(AllUnitsSelec_group2,1),ones(1,size(AllUnitsSelec_group2,2)));
    % figure('Position',[219 303 550 400]);
    % PlotCellData(AllUnitsSelec_group1,colorset{1},2,'-','o',colorset{1},colorset{1},10,-0.5-1);
    % PlotCellData(AllUnitsSelec_group2,colorset{2},2,'-','o',colorset{2},colorset{2},10,-0.5-1);
    % PlotEventCurve(SampOdorLen,DelayLen,TestOdorLen,RespWindLen,2,1);
    % SetXYaxisProperty(0,1,SampOdorLen+DelayLen+TestOdorLen+RespWindLen,-1,SampOdorLen+DelayLen,'Time from sample onset (s)',0,0.1,1,0,1,['Population averaged ' selectype],16,18); box off;
    % % ranksum test for sample-period values
    % Psample = ranksum(AllUnitsSelec_group1{1+SampOdorLen},AllUnitsSelec_group2{1+SampOdorLen});
    % title(['Psample = ' num2str(Psample) '; NUMhealthy = ' num2str(numel(AllUnitsSelec_group1{1})) '; NUMpd = ' num2str(numel(AllUnitsSelec_group2{1}))]);
    % % Tw-ANOVA-md for delay-period values
    % Ps = GetDataMatrixForMixedRepeatedAnova(AllUnitsSelec_group1(:,3:end),AllUnitsSelec_group2(:,1+SampOdorLen+1:end),fullfile(homedir,strcat('DelayBinBased',Reg,['AllUnits' selectype '_'],phase)));
    % set(gcf,'Renderer','Painter'); saveas(gcf,fullfile(homedir,sprintf('Compare all bin-based %s all neurons %s_%s',Reg,selectype,phase)),'fig'); close all;
end



function [PerceptionUnitsSelec,MemoryUnitsSelec,MemoryUnitsShuffledSelec,AllUnitsSelec] = PerceptionMemoryAllUnitsCodingAbility(homedir,reg,FRthreshold,FAthreshold,group,BaselineDuration,SampleOdorLength,SelecType)

%% Load result
fprintf('Getting real and shuffled selectivity of %s memory neurons in %s group\n',reg,group);
if contains(homedir,'ActivationOnOff')
    load(fullfile(homedir,'UnitsInformation_LaserOnOff.mat'));
    load(fullfile(homedir,strcat('UnitsShuffledMutualInformation_',group,'.mat')),'AllUnitsShuffledMI');
else
    load(fullfile(homedir,group,'Training',strcat('UnitsInformation_',group,'.mat')));
    load(fullfile(homedir,group,'Training',strcat('UnitsShuffledMutualInformation_',group,'.mat')),'AllUnitsShuffledMI');
end

%% Target neurons information
IsTarRegUnit = cellfun(@(x) contains(x,reg),UnitsInformation(:,3),'UniformOutput',true);
IsFrQualifiedUnit = cell2mat(UnitsInformation(:,7))>=FRthreshold;
IsFArateQualifiedUnit = cell2mat(UnitsInformation(:,8))<=FAthreshold;
TarUnitsInfo = UnitsInformation(IsTarRegUnit&IsFrQualifiedUnit&IsFArateQualifiedUnit,:);
TarUnitsShuffledMI = AllUnitsShuffledMI(IsTarRegUnit&IsFrQualifiedUnit&IsFArateQualifiedUnit,:);

%% Perception neurons second-based selectivity
SampleBinID = BaselineDuration + SampleOdorLength;
if contains(homedir,'ActivationOnOff')
    PerceptionUnitsSelec = [];
    for iUnit = 1:size(TarUnitsInfo,1)
        if ismember(SampleBinID,TarUnitsInfo{iUnit,27}.(group))
            PerceptionUnitsSelec = [PerceptionUnitsSelec; TarUnitsInfo{iUnit,33+SelecType}.(group)];
        end
    end
else
    IsPerceptionUnit = cellfun(@(x) ismember(SampleBinID,x),TarUnitsInfo(:,27),'UniformOutput',true);
    PerceptionUnitsSelec = cell2mat(TarUnitsInfo(IsPerceptionUnit,33+SelecType));
end

%% Memory neurons second-based selectivity
if contains(homedir,'ActivationOnOff')
    MemoryUnitsSelec = [];
    MemoryUnitsShuffledSelec = [];
    for iUnit = 1:size(TarUnitsInfo,1)
        if strcmp(TarUnitsInfo{iUnit,22}.(group),'Transient') || strcmp(TarUnitsInfo{iUnit,22}.(group),'Sustained')
            MemoryUnitsSelec = [MemoryUnitsSelec; TarUnitsInfo{iUnit,33+SelecType}.(group)];
            MemoryUnitsShuffledSelec = [MemoryUnitsShuffledSelec; TarUnitsShuffledMI{iUnit}];
        end
    end
else
    IsMemoryUnit = cellfun(@(x) strcmp(x,'Transient')|strcmp(x,'Sustained'),TarUnitsInfo(:,22),'UniformOutput',true);
    MemoryUnitsSelec = cell2mat(TarUnitsInfo(IsMemoryUnit,33+SelecType));
    MemoryUnitsShuffledSelec = cell2mat(TarUnitsShuffledMI(IsMemoryUnit,:));
end

%% All neurons second-based selectivity
if contains(homedir,'ActivationOnOff')
    AllUnitsSelec = [];
    for iUnit = 1:size(TarUnitsInfo,1)
        AllUnitsSelec = [AllUnitsSelec; TarUnitsInfo{iUnit,33+SelecType}.(group)];
    end
else
    AllUnitsSelec = cell2mat(TarUnitsInfo(:,33+SelecType));
end
end
