%% All neurons' sample-odor selectivity + MI + AUC + PEV
clear; clc; close all;
addpath(genpath('/home/yaojian/Codes/Function'));
tic

%% 1. Core parameter configuration
AnalysisMode = 1;        % 1: healthy  2: laser on/off
Group = 'Healthy';
TimeGain = 10;          
ColorSet = {[1 0 0],[0 0 1],[0 0 0],[0 1 0]}; % Plot color scheme

% assign path/task params by AnalysisMode (no need to modify)
if AnalysisMode == 1
    homedir = fullfile('/home/yaojian/NoLaserinODPA',Group,'Training');
    SampOdorLen=1; DelayLen=10; TestOdorLen=1; RespWinLen=1; ItiLen=15;
elseif AnalysisMode == 2
    Group = 'LaserOnOff';
    homedir = '/home/yaojian/LaserActivationOnOffinODPA/Training';
    SampOdorLen=1; DelayLen=6; TestOdorLen=1; RespWinLen=1; ItiLen=10;
end
DataFile = 'IndividualSessionAllUnitsInformation.mat';
BaseLen = ItiLen - 2;
ShownBaseLen = 2;
BinNumForSelectivity = 10; % bin number for selectivity analysis (bin width for ranksum test)

% AUC specific params
AUC_Params.IsUsingDVOrFR = 1;    % 1: decisionVariable  2: firing rate
AUC_Params.IsPerformStatTest = 0;% 0: no test  1: permutation test
AUC_Params.ShuffledTimes = 1000; % shuffle times for stat test
AUC_Params.WorkerNum = 30;       % parpool workers
AUC_Params.AnalysisWindow = 3;   % 300-msec analysis window
AUC_Params.SlidingWindow = 1;    % 100-msec sliding window

%% 2. Load data
FileList = dir(fullfile(homedir,'*','*',DataFile));
UnitsInformation = [];
for iSess = 1:size(FileList,1)
    disp(['Collecting raw data: Session ' num2str(iSess) ' / ' num2str(size(FileList,1))]);
    load(fullfile(FileList(iSess).folder,FileList(iSess).name),'data');
    UnitsInformation = [UnitsInformation; data];
end
UnitNum = size(UnitsInformation,1);
UnitsSelectivity = cell(UnitNum,17);

%% 3. Batch analysis
% initialize result containers
SecBasedMI = cell(UnitNum,1);  SecBasedAUC = cell(UnitNum,1);  SecBasedPEV = cell(UnitNum,1);
tempGroupID = [];

for iUnit = 1:UnitNum
    disp(['Processing neuron: ' num2str(iUnit) ' / ' num2str(UnitNum)]);
    FR_S1 = []; FR_S2 = []; % S1/S2 firing rate
    
    % --------------------------
    % step 1: Odor selectivity analysis (PSTH + coding persistence type + memory preference)
    % --------------------------
    trialMark = UnitsInformation{iUnit,10};
    frData = UnitsInformation{iUnit,12};
    % "laser on/off" or "no laser"
    if AnalysisMode == 1
        UnitsSelectivity = procNoLaser(UnitsSelectivity,iUnit,trialMark,frData,BaseLen,ShownBaseLen,TimeGain,BinNumForSelectivity,SampOdorLen,DelayLen,TestOdorLen,RespWinLen);
        % FR for subsequent AUC/PEV/MI
        FR_S1 = UnitsSelectivity{iUnit,1};
        FR_S2 = UnitsSelectivity{iUnit,2};
    else
        UnitsSelectivity = procLaserOnOff(UnitsSelectivity,iUnit,trialMark,frData,BaseLen,ShownBaseLen,TimeGain,BinNumForSelectivity,SampOdorLen,DelayLen,TestOdorLen,RespWinLen);
        SecBasedMI{iUnit} = struct('laseroff',[],'laseron',[]);
        SecBasedAUC{iUnit} = struct('laseroff',[],'laseron',[]);
        SecBasedPEV{iUnit} = struct('laseroff',[],'laseron',[]);
        % FR for subsequent AUC/PEV/MI
        FR_S1_laseroff = UnitsSelectivity{iUnit,1}.laseroff;
        FR_S2_laseroff = UnitsSelectivity{iUnit,2}.laseroff;
        FR_S1_laseron = UnitsSelectivity{iUnit,1}.laseron;
        FR_S2_laseron = UnitsSelectivity{iUnit,2}.laseron;
    end
    % Plot PSTH
    plotPSTH(UnitsSelectivity,iUnit,BaseLen,SampOdorLen,DelayLen,TestOdorLen,RespWinLen,ItiLen,TimeGain,BinNumForSelectivity,ColorSet,homedir,UnitsInformation,AnalysisMode);

    % --------------------------
    % Step 2: Second-based data preprocess
    % --------------------------
    SecNum = floor(size(FR_S1,2)/TimeGain); % Total second-based bins
    if AnalysisMode == 1
        % group ID for PEV
        tempGroupID = vertcat(ones(size(FR_S1,1),1),2*ones(size(FR_S2,1),1));
        % smooth FR for AUC
        [smoothFR_S1,smoothFR_S2] = smoothFR(FR_S1,FR_S2,AUC_Params);
    else
        % laser off
        tempGroupID_laseroff = vertcat(ones(size(FR_S1_laseroff,1),1),2*ones(size(FR_S2_laseroff,1),1));
        [smoothFR_S1_laseroff,smoothFR_S2_laseroff] = smoothFR(FR_S1_laseroff,FR_S2_laseroff,AUC_Params);
        % laser on
        tempGroupID_laseron = vertcat(ones(size(FR_S1_laseron,1),1),2*ones(size(FR_S2_laseron,1),1));
        [smoothFR_S1_laseron,smoothFR_S2_laseron] = smoothFR(FR_S1_laseron,FR_S2_laseron,AUC_Params);
    end

    % --------------------------
    % Step 3: MI/AUC/PEV calculation (second-based)
    % --------------------------
    for iSec = 1:SecNum
        if AnalysisMode == 1
            % Extract second-based FR
            [secFR_S1,secFR_S2,secSmoothFR_S1,secSmoothFR_S2] = getSecBasedFR(FR_S1,FR_S2,smoothFR_S1,smoothFR_S2,iSec,TimeGain);
            % Mutual Information (MI)
            SecBasedMI{iUnit} = [SecBasedMI{iUnit} calcMI(secFR_S1,secFR_S2)];
            % Area Under ROC (AUC)
            SecBasedAUC{iUnit} = [SecBasedAUC{iUnit} calcAUC(secSmoothFR_S1,secSmoothFR_S2,AUC_Params)];
            % Percent of Explained Variance (PEV)
            SecBasedPEV{iUnit} = [SecBasedPEV{iUnit} calcPEV(secFR_S1,secFR_S2,tempGroupID)];
        else
            % laser off
            [secFR_S1_laseroff,secFR_S2_laseroff,secSmoothFR_S1_laseroff,secSmoothFR_S2_laseroff] = getSecBasedFR(FR_S1_laseroff,FR_S2_laseroff,smoothFR_S1_laseroff,smoothFR_S2_laseroff,iSec,TimeGain);
            SecBasedMI{iUnit}.laseroff = [SecBasedMI{iUnit}.laseroff calcMI(secFR_S1_laseroff,secFR_S2_laseroff)];
            SecBasedAUC{iUnit}.laseroff = [SecBasedAUC{iUnit}.laseroff calcAUC(secSmoothFR_S1_laseroff,secSmoothFR_S2_laseroff,AUC_Params)];
            SecBasedPEV{iUnit}.laseroff = [SecBasedPEV{iUnit}.laseroff calcPEV(secFR_S1_laseroff,secFR_S2_laseroff,tempGroupID)];
            % laser on
            [secFR_S1_laseron,secFR_S2_laseron,secSmoothFR_S1_laseron,secSmoothFR_S2_laseron] = getSecBasedFR(FR_S1_laseron,FR_S2_laseron,smoothFR_S1_laseron,smoothFR_S2_laseron,iSec,TimeGain);
            SecBasedMI{iUnit}.laseron = [SecBasedMI{iUnit}.laseron calcMI(secFR_S1_laseron,secFR_S2_laseron)];
            SecBasedAUC{iUnit}.laseron = [SecBasedAUC{iUnit}.laseron calcAUC(secSmoothFR_S1_laseron,secSmoothFR_S2_laseron,AUC_Params)];
            SecBasedPEV{iUnit}.laseron = [SecBasedPEV{iUnit}.laseron calcPEV(secFR_S1_laseron,secFR_S2_laseron,tempGroupID)];
        end
    end

    % Clear temp vars to save memory
    clearvars -except AnalysisMode Group homedir UnitNum TimeGain ColorSet BinNumForSelectivity BaseLen ShownBaseLen SampOdorLen DelayLen TestOdorLen RespWinLen ItiLen AUC_Params FileList UnitsInformation UnitsSelectivity SecBasedMI SecBasedAUC SecBasedPEV iUnit
end

%% 4. Merge results and save
UnitsInformation = horzcat(UnitsInformation,UnitsSelectivity,SecBasedAUC,SecBasedPEV,SecBasedMI); % Merge selectivity
save(fullfile(homedir,sprintf('UnitsInformation_%s.mat',Group)),'UnitsInformation','-v7.3');
toc

%% 5. Final information
disp('=============================================');
disp(['Analysis Completed! Group: ' Group]);
disp(['Result Saved to: ' fullfile(homedir,sprintf('UnitsInformation_%s.mat',Group))]);
disp('=============================================');

%% --------------------------
function UnitsSelectivity = procNoLaser(UnitsSelectivity,iUnit,trialMark,frData,BaseLen,ShownBaseLen,TimeGain,BinNumForSelectivity,SampOdorLen,DelayLen,TestOdorLen,RespWinLen)
    S1TrialsTD = find(trialMark(:,1)==1); S2TrialsTD = find(trialMark(:,1)==2);
    % extract FR
    S1TrialFR = frData(S1TrialsTD); 
    S2TrialFR = frData(S2TrialsTD);
    UnitsSelectivity{iUnit,1} = vertcat(S1TrialFR{:});
    UnitsSelectivity{iUnit,2} = vertcat(S2TrialFR{:});
    % normalize FR
    UnitsSelectivity{iUnit,3} = normFR(UnitsSelectivity{iUnit,1},BaseLen,ShownBaseLen,TimeGain);
    UnitsSelectivity{iUnit,4} = normFR(UnitsSelectivity{iUnit,2},BaseLen,ShownBaseLen,TimeGain);
    % real/shuffled selectivity
    [UnitsSelectivity{iUnit,5}{1,1},UnitsSelectivity{iUnit,5}{2,1}] = GetRealShuffleData({vertcat(frData{:})},vertcat({S1TrialsTD},{S2TrialsTD}),[]);
    % significant bin/pattern
    [PutaSigSelecBinID,PutaSigSelecPattern] = GetPutativeSigUnitID(UnitsSelectivity(iUnit,1),UnitsSelectivity(iUnit,2),BinNumForSelectivity,SampOdorLen,DelayLen,TestOdorLen,1,RespWinLen,TimeGain);
    % coding persistence type/selectivity params
    [UnitsSelectivity{iUnit,6},UnitsSelectivity{iUnit,7},UnitsSelectivity{iUnit,8},UnitsSelectivity{iUnit,9}{1,1},UnitsSelectivity{iUnit,9}{1,2},UnitsSelectivity{iUnit,10},UnitsSelectivity{iUnit,11},UnitsSelectivity{iUnit,12}] = JudgeIndividualUnitSustTranNonmem(PutaSigSelecPattern,PutaSigSelecBinID{1},UnitsSelectivity{iUnit,1},UnitsSelectivity{iUnit,2},BaseLen,SampOdorLen,DelayLen,BinNumForSelectivity);
    % odor preference/FR modulation
    UnitsSelectivity{iUnit,13} = JudgeIndividualUnitDelayPreferenceAndModulation(UnitsSelectivity{iUnit,1},UnitsSelectivity{iUnit,2},UnitsSelectivity{iUnit,8},BaseLen,ShownBaseLen,SampOdorLen,DelayLen,TimeGain);
    % FR by trial outcome (Hit/Miss/FA/CR)
    allFR = vertcat(frData{:});
    UnitsSelectivity{iUnit,14}{1,1} = getFRbyOutcome(allFR,trialMark,'S1','Hit');
    UnitsSelectivity{iUnit,14}{1,2} = getFRbyOutcome(allFR,trialMark,'S2','Hit');
    UnitsSelectivity{iUnit,15}{1,1} = getFRbyOutcome(allFR,trialMark,'S1','Miss');
    UnitsSelectivity{iUnit,15}{1,2} = getFRbyOutcome(allFR,trialMark,'S2','Miss');
    UnitsSelectivity{iUnit,16}{1,1} = getFRbyOutcome(allFR,trialMark,'S1','FalseAlarm');
    UnitsSelectivity{iUnit,16}{1,2} = getFRbyOutcome(allFR,trialMark,'S2','FalseAlarm');
    UnitsSelectivity{iUnit,17}{1,1} = getFRbyOutcome(allFR,trialMark,'S1','CorrectRejection');
    UnitsSelectivity{iUnit,17}{1,2} = getFRbyOutcome(allFR,trialMark,'S2','CorrectRejection');
end

function UnitsSelectivity = procLaserOnOff(UnitsSelectivity,iUnit,trialMark,frData,BaseLen,ShownBaseLen,TimeGain,BinNumForSelectivity,SampOdorLen,DelayLen,TestOdorLen,RespWinLen)
    % Trial ID split by laser state
    S1_off = find(trialMark.laseroff(:,1)==1); S1_on = find(trialMark.laseron(:,1)==1);
    S2_off = find(trialMark.laseroff(:,1)==2); S2_on = find(trialMark.laseron(:,1)==2);
    % extract FR (laser off/on)
    S1TrialFR_Off = frData.laseroff(S1_off);
    S1TrialFR_On = frData.laseron(S1_on);
    S2TrialFR_Off = frData.laseroff(S2_off);
    S2TrialFR_On = frData.laseron(S2_on);
    UnitsSelectivity{iUnit,1}.laseroff = vertcat(S1TrialFR_Off{:});
    UnitsSelectivity{iUnit,1}.laseron  = vertcat(S1TrialFR_On{:});
    UnitsSelectivity{iUnit,2}.laseroff = vertcat(S2TrialFR_Off{:});
    UnitsSelectivity{iUnit,2}.laseron  = vertcat(S2TrialFR_On{:});
    % normalize FR (laser off/on)
    UnitsSelectivity{iUnit,3}.laseroff = normFR(UnitsSelectivity{iUnit,1}.laseroff,BaseLen,ShownBaseLen,TimeGain);
    UnitsSelectivity{iUnit,3}.laseron  = normFR(UnitsSelectivity{iUnit,1}.laseron,BaseLen,ShownBaseLen,TimeGain);
    UnitsSelectivity{iUnit,4}.laseroff = normFR(UnitsSelectivity{iUnit,2}.laseroff,BaseLen,ShownBaseLen,TimeGain);
    UnitsSelectivity{iUnit,4}.laseron  = normFR(UnitsSelectivity{iUnit,2}.laseron,BaseLen,ShownBaseLen,TimeGain);
    % Real/shuffled selectivity (laser off/on)
    [UnitsSelectivity{iUnit,5}.laseroff{1,1},UnitsSelectivity{iUnit,5}.laseroff{2,1}] = GetRealShuffleData({vertcat(frData.laseroff{:})},vertcat({S1_off},{S2_off}),[]);
    [UnitsSelectivity{iUnit,5}.laseron{1,1},UnitsSelectivity{iUnit,5}.laseron{2,1}] = GetRealShuffleData({vertcat(frData.laseron{:})},vertcat({S1_on},{S2_on}),[]);
    % Laser Off: coding persistence type/selectivity/preference
    [PutaSigSelecBinID_off,PutaSigSelecPattern_off] = GetPutativeSigUnitID({UnitsSelectivity{iUnit,1}.laseroff},{UnitsSelectivity{iUnit,2}.laseroff},BinNumForSelectivity,SampOdorLen,DelayLen,TestOdorLen,1,RespWinLen,TimeGain);
    [UnitsSelectivity{iUnit,6}.laseroff,UnitsSelectivity{iUnit,7}.laseroff,UnitsSelectivity{iUnit,8}.laseroff,UnitsSelectivity{iUnit,9}.laseroff{1,1},UnitsSelectivity{iUnit,9}.laseroff{1,2},UnitsSelectivity{iUnit,10}.laseroff,UnitsSelectivity{iUnit,11}.laseroff,UnitsSelectivity{iUnit,12}.laseroff] = JudgeIndividualUnitSustTranNonmem(PutaSigSelecPattern_off,PutaSigSelecBinID_off{1},UnitsSelectivity{iUnit,1}.laseroff,UnitsSelectivity{iUnit,2}.laseroff,BaseLen,SampOdorLen,DelayLen,BinNumForSelectivity);    
    UnitsSelectivity{iUnit,13}.laseroff = JudgeIndividualUnitDelayPreferenceAndModulation(UnitsSelectivity{iUnit,1}.laseroff,UnitsSelectivity{iUnit,2}.laseroff,UnitsSelectivity{iUnit,8}.laseroff,BaseLen,ShownBaseLen,SampOdorLen,DelayLen,TimeGain);
    % Laser On: coding persistence type/selectivity/preference
    [PutaSigSelecBinID_on,PutaSigSelecPattern_on] = GetPutativeSigUnitID({UnitsSelectivity{iUnit,1}.laseron},{UnitsSelectivity{iUnit,2}.laseron},BinNumForSelectivity,SampOdorLen,DelayLen,TestOdorLen,1,RespWinLen,TimeGain);
    [UnitsSelectivity{iUnit,6}.laseron,UnitsSelectivity{iUnit,7}.laseron,UnitsSelectivity{iUnit,8}.laseron,UnitsSelectivity{iUnit,9}.laseron{1,1},UnitsSelectivity{iUnit,9}.laseron{1,2},UnitsSelectivity{iUnit,10}.laseron,UnitsSelectivity{iUnit,11}.laseron,UnitsSelectivity{iUnit,12}.laseron] = JudgeIndividualUnitSustTranNonmem(PutaSigSelecPattern_on,PutaSigSelecBinID_on{1},UnitsSelectivity{iUnit,1}.laseron,UnitsSelectivity{iUnit,2}.laseron,BaseLen,SampOdorLen,DelayLen,BinNumForSelectivity);
    UnitsSelectivity{iUnit,13}.laseron = JudgeIndividualUnitDelayPreferenceAndModulation(UnitsSelectivity{iUnit,1}.laseron,UnitsSelectivity{iUnit,2}.laseron,UnitsSelectivity{iUnit,8}.laseron,BaseLen,ShownBaseLen,SampOdorLen,DelayLen,TimeGain);
    % FR by outcome (laser off/on)
    UnitsSelectivity{iUnit,14} = getFRlaser(frData,trialMark,'Hit');
    UnitsSelectivity{iUnit,15} = getFRlaser(frData,trialMark,'Miss');
    UnitsSelectivity{iUnit,16} = getFRlaser(frData,trialMark,'FalseAlarm');
    UnitsSelectivity{iUnit,17} = getFRlaser(frData,trialMark,'CorrectRejection');
end

% Normalize FR (baseline correction + smooth)
function normFR = normFR(frMat,BaseLen,ShownBaseLen,TimeGain)
    baseStart = (BaseLen-ShownBaseLen)*TimeGain + 2;
    baseEnd = BaseLen*TimeGain + 1;
    baseFR = mean(frMat(:,baseStart:baseEnd),1);
    normFR = smooth((mean(frMat,1) - mean(baseFR))./std(baseFR),3)';
end

% Get FR by trial outcome (No Laser mode)
function fr = getFRbyOutcome(allFR,trialMark,SampleID,OutcomeID)
    [TarSample,TarOutcome] = getTrialID(SampleID,OutcomeID);
    fr = allFR(trialMark(:,1)==TarSample & trialMark(:,3)==TarOutcome,:);
end

% Get FR by outcome (LaserOnOff mode)
function frStruct = getFRlaser(frData,trialMark,OutcomeID)
    frStruct.laseroff{1,1} = getFRbyOutcome(vertcat(frData.laseroff{:}),trialMark.laseroff,'S1',OutcomeID);
    frStruct.laseroff{1,2} = getFRbyOutcome(vertcat(frData.laseroff{:}),trialMark.laseroff,'S2',OutcomeID);
    frStruct.laseron{1,1}  = getFRbyOutcome(vertcat(frData.laseron{:}),trialMark.laseron,'S1',OutcomeID);
    frStruct.laseron{1,2}  = getFRbyOutcome(vertcat(frData.laseron{:}),trialMark.laseron,'S2',OutcomeID);
end

% Translate Sample/Outcome ID to numerical value
function [TarSample,TarOutcome] = getTrialID(SampleID,OutcomeID)
    TarSample = strcmp(SampleID,'S2') + 1; % S1=1, S2=2
    if strcmp(OutcomeID,'Hit'); TarOutcome=1;
    elseif strcmp(OutcomeID,'Miss'); TarOutcome=2;
    elseif strcmp(OutcomeID,'FalseAlarm'); TarOutcome=3;
    elseif strcmp(OutcomeID,'CorrectRejection'); TarOutcome=4;
    end
end

% PSTH plot
function plotPSTH(UnitsSelectivity,iUnit,BaseLen,SampOdorLen,DelayLen,TestOdorLen,RespWinLen,ItiLen,TimeGain,BinNumForSelectivity,ColorSet,homedir,UnitsInformation,AnalysisMode)
    fig = figure('position',[200 300 530 420]);
    if AnalysisMode ~= 1
        % single PSTH (Healthy/PDmodel)
        fr1 = UnitsSelectivity{iUnit,1}; fr2 = UnitsSelectivity{iUnit,2};
        MaxFR = 1.5*max(horzcat(mean(fr1,1),mean(fr2,1)));
        plotshadow(fr1,ColorSet{1},2,3,-1*(BaseLen*TimeGain+1.5)/TimeGain,TimeGain);
        plotshadow(fr2,ColorSet{2},2,3,-1*(BaseLen*TimeGain+1.5)/TimeGain,TimeGain);
        PlotEventCurve(0,SampOdorLen,DelayLen,TestOdorLen,RespWinLen,2,MaxFR);
        plotSigBin(UnitsSelectivity{iUnit,11},MaxFR,BaseLen,TimeGain,BinNumForSelectivity);
        SetXYaxisProperty(-1*BaseLen,1,SampOdorLen+DelayLen+TestOdorLen+RespWinLen+ItiLen,-0.5,SampOdorLen+DelayLen+TestOdorLen+RespWinLen,'Time from sample onset (s)',0,ceil(round(MaxFR)/6),6*ceil(round(MaxFR)/6),0,MaxFR,'Firing rate (Hz)',12,12);
        saveName = sprintf('Unit%d_%s_%s_ID %d_PSTH',iUnit,UnitsInformation{iUnit,1},UnitsInformation{iUnit,2},UnitsInformation{iUnit,4});
    else
        % double PSTH (laseroff + laseron)
        fr1_off = UnitsSelectivity{iUnit,1}.laseroff; fr1_on = UnitsSelectivity{iUnit,1}.laseron;
        fr2_off = UnitsSelectivity{iUnit,2}.laseroff; fr2_on = UnitsSelectivity{iUnit,2}.laseron;
        MaxFR = 1.5*max(horzcat(mean(fr1_off,1),mean(fr1_on,1),mean(fr2_off,1),mean(fr2_on,1)));
        % laser off subplot
        subplot(1,2,1);
        plotshadow(fr1_off,ColorSet{1},2,3,-1*(BaseLen*TimeGain+1.5)/TimeGain,TimeGain);
        plotshadow(fr2_off,ColorSet{2},2,3,-1*(BaseLen*TimeGain+1.5)/TimeGain,TimeGain);
        PlotEventCurve(0,SampOdorLen,DelayLen,TestOdorLen,RespWinLen,2,MaxFR);
        plotSigBin(UnitsSelectivity{iUnit,11}.laseroff,MaxFR,BaseLen,TimeGain,BinNumForSelectivity);
        SetXYaxisProperty(-1*BaseLen,1,SampOdorLen+DelayLen+TestOdorLen+RespWinLen+ItiLen,-0.5,SampOdorLen+DelayLen+TestOdorLen+RespWinLen,'Time from sample onset (s)',0,ceil(round(MaxFR)/6),6*ceil(round(MaxFR)/6),0,MaxFR,'Firing rate (Hz)',12,12);
        box off;
        % Laser On subplot
        subplot(1,2,2);
        plotshadow(fr1_on,ColorSet{1},2,3,-1*(BaseLen*TimeGain+1.5)/TimeGain,TimeGain);
        plotshadow(fr2_on,ColorSet{2},2,3,-1*(BaseLen*TimeGain+1.5)/TimeGain,TimeGain);
        PlotEventCurve(0,SampOdorLen,DelayLen,TestOdorLen,RespWinLen,2,MaxFR);
        plotSigBin(UnitsSelectivity{iUnit,11}.laseron,MaxFR,BaseLen,TimeGain,BinNumForSelectivity);
        SetXYaxisProperty(-1*BaseLen,1,SampOdorLen+DelayLen+TestOdorLen+RespWinLen+ItiLen,-0.5,SampOdorLen+DelayLen+TestOdorLen+RespWinLen,'Time from sample onset (s)',0,ceil(round(MaxFR)/6),6*ceil(round(MaxFR)/6),0,MaxFR,'Firing rate (Hz)',12,12);
        box off;
        saveName = sprintf('Unit%d_%s_%s_ID %d_LaserOnOff_PSTH',iUnit,UnitsInformation{iUnit,1},UnitsInformation{iUnit,2},UnitsInformation{iUnit,4});
    end
    % Save PSTH figure
    box off; set(fig,'Renderer','Painter');
    saveas(fig,fullfile(homedir,saveName),'fig'); close(fig);
end

% Sub8: Plot significant selectivity bins
function plotSigBin(sigBin,MaxFR,BaseLen,TimeGain,BinNumForSelectivity)
    if ~isempty(sigBin)
        boundary_right = (sigBin - BaseLen*TimeGain/BinNumForSelectivity)*BinNumForSelectivity/TimeGain;
        boundary_left = boundary_right - BinNumForSelectivity/TimeGain;
        boundary = vertcat(boundary_left,boundary_right);
        for j = 1:size(boundary,2)
            patch([boundary(1,j) boundary(1,j) boundary(2,j) boundary(2,j)],[0.85*MaxFR 0.87*MaxFR 0.87*MaxFR 0.85*MaxFR],[0 0 0],'edgecolor','none');
            hold on;
        end
    end
end

% Smooth FR
function [smoothFR_S1,smoothFR_S2] = smoothFR(fr_S1,fr_S2,AUC_Params)
    smoothFR_S1 = zeros(size(fr_S1,1),floor(size(fr_S1,2)-(AUC_Params.AnalysisWindow-1)));
    smoothFR_S2 = zeros(size(fr_S2,1),floor(size(fr_S2,2)-(AUC_Params.AnalysisWindow-1)));
    % smooth S1
    for iTrial = 1:size(fr_S1,1)
        for iBin = 1:AUC_Params.SlidingWindow:size(fr_S1,2)-(AUC_Params.AnalysisWindow-1)
            smoothFR_S1(iTrial,iBin) = sum(fr_S1(iTrial,iBin:iBin+AUC_Params.AnalysisWindow-1)) / AUC_Params.AnalysisWindow;
        end
    end
    % smooth S2
    for iTrial = 1:size(fr_S2,1)
        for iBin = 1:AUC_Params.SlidingWindow:size(fr_S2,2)-(AUC_Params.AnalysisWindow-1)
            smoothFR_S2(iTrial,iBin) = sum(fr_S2(iTrial,iBin:iBin+AUC_Params.AnalysisWindow-1)) / AUC_Params.AnalysisWindow;
        end
    end
end

% Get second-based FR
function [secFR_S1,secFR_S2,secSmoothFR_S1,secSmoothFR_S2] = getSecBasedFR(fr_S1,fr_S2,smoothFR_S1,smoothFR_S2,iSec,TimeGain)
% raw FR for MI/PEV
secFR_S1 = mean(fr_S1(:,2+(iSec-1)*TimeGain:1+iSec*TimeGain),2);
secFR_S2 = mean(fr_S2(:,2+(iSec-1)*TimeGain:1+iSec*TimeGain),2);
% smoothed FR for AUC
secSmoothFR_S1 = mean(smoothFR_S1(:,2+(iSec-1)*TimeGain:1+iSec*TimeGain),2);
secSmoothFR_S2 = mean(smoothFR_S2(:,2+(iSec-1)*TimeGain:1+iSec*TimeGain),2);
end

% Calculate AUC
function auc = calcAUC(secFR_S1,secFR_S2,AUC_Params)
    if AUC_Params.IsUsingDVOrFR == 1
        [tempDV_S1,tempDV_S2] = DecisionVariableCalculation(secFR_S1,secFR_S2);
        [tempTPR,tempFPR] = TprFprCalculation(tempDV_S1,tempDV_S2);
    else
        [tempTPR,tempFPR] = TprFprCalculation(secFR_S1(:)',secFR_S2(:)');
    end
    auc = AucAnalysis(tempFPR,tempTPR);
end

% Calculate PEV (ANOVA-based)
function pev = calcPEV(secFR_S1,secFR_S2,tempGroupID)
    tempData = vertcat(secFR_S1(:),secFR_S2(:));
    [~,table,~] = anovan(tempData,tempGroupID,'model','full','display','off');
    pev = (table{2,2}-table{2,3}*table{3,5}) / (table{4,2}+table{3,5});
end
