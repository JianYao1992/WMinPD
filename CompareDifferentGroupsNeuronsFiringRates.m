%% This code aims to compare memory neurons proportion between two groups.

clear; clc; close all;

addpath('D:\Codes\Function');

%% Assignment
homedir = 'G:\LaserActivationOnOffinODPA\Training';
if contains(homedir,'LaserActivation')
    Group = {'laseroff','laseron'};
    colorset = {[0 125 0]/255,[67 106 178]/255};
    BaselineLength = 8;
    DelayLength = 6;
else
    Group = {'Healthy','PDmodel'};
    colorset = {[0 0 0],[0 125 0]/255};
    BaselineLength = 13;
    DelayLength = 10;
end
phase = 'Learning';
Reg = {'aAIC','mPFC'};
FAthres = 0.0025;
SampleOdorLength = 1;
TestOdorLength = 1;
ResponseWindowLength = 1;
TimeGain = 10;
ShuffleTimes = 1000;

for iReg = 1:numel(Reg)

    %% Obtain proportion of selective neurons (including perceptual and memory neurons)
    MeanFR_Group1 = CalculateNeuronsAveragedFiringRates(homedir,Group{1},Reg{iReg},FAthres);
    MeanFR_Group2 = CalculateNeuronsAveragedFiringRates(homedir,Group{2},Reg{iReg},FAthres);

    %% Plot mean firing rates of two different groups
    figure('Position',[219 303 550 400]);
    MaxFR = 1.5*max(horzcat(mean(MeanFR_Group1,1),mean(MeanFR_Group2,1)));
    plotshadow(MeanFR_Group1, colorset{1}, 2, 3, -1*(BaselineLength+0.15), TimeGain);
    plotshadow(MeanFR_Group2, colorset{2}, 2, 3, -1*(BaselineLength+0.15), TimeGain);
    PlotEventCurve(0, SampleOdorLength, DelayLength, TestOdorLength, ResponseWindowLength, 1, MaxFR);

    % cluster-based permutation test
    [SigTime,SigLessThanChanceTime] = ClusterBasedPermutationTest('Between recordings', MeanFR_Group1, MeanFR_Group2,...
        size(MeanFR_Group1,2), ShuffleTimes, 2);
    
    % label significant time bins
    LabelSignificantPositions(horzcat(SigTime,SigLessThanChanceTime)-(BaselineLength+0.15)*TimeGain,TimeGain,MaxFR-1,colorset{1});
    SetXYaxisProperty(-1*BaselineLength,1,SampleOdorLength+DelayLength+TestOdorLength+ResponseWindowLength+BaselineLength,-0.5,SampleOdorLength+DelayLength+TestOdorLength+ResponseWindowLength,'Time from sample onset (s)',0,ceil(round(MaxFR)/6),6*ceil(round(MaxFR)/6),0,MaxFR,'Firing rate (Hz)',12,12);
    box off;

    % save figure
    title(sprintf('NUMgroup1 = %d, NUMgroup2 = %d',size(MeanFR_Group1,1),size(MeanFR_Group2,1)));
    set(gcf,'Renderer','Painter'); saveas(gcf,fullfile(homedir,sprintf('Compare %s neurons averaged firing rates_Between %s and %s_%s',Reg{iReg},Group{1},Group{2},phase)),'fig');
    close all;

end


function AveragedFiringRates = CalculateNeuronsAveragedFiringRates(Directory,Group,Region,FAthreshold)

fprintf('Processing %s group for %s\n', Group, Region);

%% Load result
if strcmp(Group,'laseroff') || strcmp(Group,'laseron')
    load(fullfile(Directory,'UnitsInformation_LaserOnoff.mat'));
else
    load(fullfile(Directory,Group,'Training',strcat('UnitsInformation_',Group,'.mat')));
end

%% Target neurons information
IsTarRegUnit = cellfun(@(x) contains(x,Region),UnitsInformation(:,3),'UniformOutput',true);
IsFArateQualifiedUnit = cell2mat(UnitsInformation(:,8)) <= FAthreshold;
TargetUnitsInfo = UnitsInformation(IsTarRegUnit & IsFArateQualifiedUnit,:);

%% All neurons' averaged firing rate
if strcmp(Group,'laseroff') || strcmp(Group,'laseron')
    Result = [];
    for iUnit = 1:size(TargetUnitsInfo,1)
        Result = [Result; {TargetUnitsInfo{iUnit,12}.(Group)}];
    end
    AveragedFiringRates = cellfun(@(x) mean(vertcat(x{:}),1),Result,'UniformOutput',0);
else
    AveragedFiringRates = cellfun(@(x) mean(vertcat(x{:}),1),TargetUnitsInfo(:,12),'UniformOutput',0);
end
AveragedFiringRates = vertcat(AveragedFiringRates{:});

end

