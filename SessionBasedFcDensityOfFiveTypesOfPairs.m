

clear; clc; close all;
addpath(genpath('/home/yaojian/Codes/Function'));

%% ===================== CONFIG PARAMETERS =====================
IsNoLaserMode = true;    % Switch working mode: true = Laser on off; false = No laser
Reg = 'mPFC-aAIC';             % Region pair: 'mPFC-mPFC'/'aAIC-aAIC'/'mPFC-aAIC'/'aAIC-mPFC'
Group = 'Healthy';             % Only effective when RunLaserCompareMode=false
binsize = '2msbin';
PairsNumthres = 6;
BinNumCriteria = 2;
% Event time parameters
ShownBaseLen = 1;
SampOdorLen = 1;
if IsNoLaserMode
    DelayLen = 10;
else
    DelayLen = 6;
end
% File path setup
if IsNoLaserMode
    workpath = fullfile('/home/yaojian/NoLaserinODPA',Group,'Training');
else
    workpath = '/home/yaojian/LaserActivationOnOffinODPA/Training';
    Colorset = {[0 125 0]/255,[67 106 178]/255};
end
%% ===========================================================================

%% Step1: Define pair mapping
switch Reg
    case 'mPFC-mPFC'
        RegPair = [3 3;4 4];
    case 'aAIC-aAIC'
        RegPair = [1 1;2 2];
    case {'mPFC-aAIC','aAIC-mPFC'}
        RegPair = [1 3;3 1;2 4;4 2];
end

%% Step2: Load FC information file & extract unique mouse/day
if IsNoLaserMode
    load(fullfile(workpath,sprintf('FCinformation_%s_-1_0_%s.mat',binsize,Group)));
    [UniqMouse,UniqDay] = meshgrid(unique(Pair.mouse),unique(Pair.learningday));
else
    load(fullfile(workpath,sprintf('FCinformation_%s_-1_0_LaserOnOff.mat',binsize)));
    [UniqMouse,UniqDay] = meshgrid(unique(Pair_laseroff.mouse),unique(Pair_laseroff.learningday));
end

%% Step3: Preallocate struct for FC density results
FCdensity = struct();
% Shared category storage arrays
catNames = {'ConAct','ConInact','InconAct','InconInact','nonmemory'};
if IsNoLaserMode
    for cat = catNames
        eval(sprintf('PairNum_%s = zeros(numel(UniqMouse),DelayLen);',cat{1}));
        eval(sprintf('FcPairNum_s1_%s = zeros(numel(UniqMouse),DelayLen);',cat{1}));
        eval(sprintf('FcPairNum_s2_%s = zeros(numel(UniqMouse),DelayLen);',cat{1}));
    end
else
    FCdensity.laseron = struct();
    FCdensity.laseroff = struct();
    for cat = catNames
        eval(sprintf('PairNum_%s_laseron = zeros(numel(UniqMouse),DelayLen);',cat{1}));
        eval(sprintf('PairNum_%s_laseroff = zeros(numel(UniqMouse),DelayLen);',cat{1}));
        eval(sprintf('FcPairNum_s1_%s_laseron = zeros(numel(UniqMouse),DelayLen);',cat{1}));
        eval(sprintf('FcPairNum_s2_%s_laseron = zeros(numel(UniqMouse),DelayLen);',cat{1}));
        eval(sprintf('FcPairNum_s1_%s_laseroff = zeros(numel(UniqMouse),DelayLen);',cat{1}));
        eval(sprintf('FcPairNum_s2_%s_laseroff = zeros(numel(UniqMouse),DelayLen);',cat{1}));
    end
end

%% Step4: Loop over each delay time bin
for iBin = 1:DelayLen
    % Load bin-wise FC data file
    if IsNoLaserMode
        tempdata = load(fullfile(workpath,sprintf('FCinformation_%s_%d_%d_%s.mat',binsize,iBin,iBin+1,Group)));
    else
        tempdata = load(fullfile(workpath,sprintf('FCinformation_%s_%d_%d_LaserOnOff.mat',binsize,iBin,iBin+1)));
    end

    % Iterate all sessions
    for iFile = 1:numel(UniqMouse)
        mouseID = UniqMouse(iFile);
        dayID = UniqDay(iFile);
        % --------------------------
        % Calculate total valid neuron pairs for 5 categories
        % --------------------------
        if IsNoLaserMode
            PairNum_ConAct(iFile,iBin) = CountConActPair(tempdata.Pair,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_ConInact(iFile,iBin) = CountConInactPair(tempdata.Pair,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_InconAct(iFile,iBin) = CountInconActPair(tempdata.Pair,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_InconInact(iFile,iBin) = CountInconInactPair(tempdata.Pair,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_nonmemory(iFile,iBin) = CountNonMemPair(tempdata.Pair,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen);
        else
            % Laser OFF group pair count
            PairNum_ConAct_laseroff(iFile,iBin) = CountConActPair(tempdata.Pair_laseroff,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_ConInact_laseroff(iFile,iBin) = CountConInactPair(tempdata.Pair_laseroff,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_InconAct_laseroff(iFile,iBin) = CountInconActPair(tempdata.Pair_laseroff,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_InconInact_laseroff(iFile,iBin) = CountInconInactPair(tempdata.Pair_laseroff,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_nonmemory_laseroff(iFile,iBin) = CountNonMemPair(tempdata.Pair_laseroff,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen);
            % Laser ON group pair count
            PairNum_ConAct_laseron(iFile,iBin) = CountConActPair(tempdata.Pair_laseron,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_ConInact_laseron(iFile,iBin) = CountConInactPair(tempdata.Pair_laseron,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_InconAct_laseron(iFile,iBin) = CountInconActPair(tempdata.Pair_laseron,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_InconInact_laseron(iFile,iBin) = CountInconInactPair(tempdata.Pair_laseron,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen,iBin);
            PairNum_nonmemory_laseron(iFile,iBin) = CountNonMemPair(tempdata.Pair_laseron,mouseID,dayID,RegPair,ShownBaseLen,SampOdorLen,DelayLen);
        end

        % --------------------------
        % Calculate significant FC pairs in S1 & S2 trials
        % --------------------------
        if IsNoLaserMode
            [FcPairNum_s1_ConAct(iFile,iBin),FcPairNum_s2_ConAct(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1,tempdata.FCPair_s2,mouseID,dayID,RegPair,Reg,'ConAct',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_ConInact(iFile,iBin),FcPairNum_s2_ConInact(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1,tempdata.FCPair_s2,mouseID,dayID,RegPair,Reg,'ConInact',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_InconAct(iFile,iBin),FcPairNum_s2_InconAct(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1,tempdata.FCPair_s2,mouseID,dayID,RegPair,Reg,'InconAct',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_InconInact(iFile,iBin),FcPairNum_s2_InconInact(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1,tempdata.FCPair_s2,mouseID,dayID,RegPair,Reg,'InconInact',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_nonmemory(iFile,iBin),FcPairNum_s2_nonmemory(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1,tempdata.FCPair_s2,mouseID,dayID,RegPair,Reg,'nonmemory',ShownBaseLen,SampOdorLen,DelayLen,iBin);
        else
            % Laser OFF S1/S2 FC pair number
            [FcPairNum_s1_ConAct_laseroff(iFile,iBin),FcPairNum_s2_ConAct_laseroff(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1_laseroff,tempdata.FCPair_s2_laseroff,mouseID,dayID,RegPair,Reg,'ConAct',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_ConInact_laseroff(iFile,iBin),FcPairNum_s2_ConInact_laseroff(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1_laseroff,tempdata.FCPair_s2_laseroff,mouseID,dayID,RegPair,Reg,'ConInact',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_InconAct_laseroff(iFile,iBin),FcPairNum_s2_InconAct_laseroff(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1_laseroff,tempdata.FCPair_s2_laseroff,mouseID,dayID,RegPair,Reg,'InconAct',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_InconInact_laseroff(iFile,iBin),FcPairNum_s2_InconInact_laseroff(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1_laseroff,tempdata.FCPair_s2_laseroff,mouseID,dayID,RegPair,Reg,'InconInact',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_nonmemory_laseroff(iFile,iBin),FcPairNum_s2_nonmemory_laseroff(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1_laseroff,tempdata.FCPair_s2_laseroff,mouseID,dayID,RegPair,Reg,'nonmemory',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            % Laser ON S1/S2 FC pair number
            [FcPairNum_s1_ConAct_laseron(iFile,iBin),FcPairNum_s2_ConAct_laseron(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1_laseron,tempdata.FCPair_s2_laseron,mouseID,dayID,RegPair,Reg,'ConAct',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_ConInact_laseron(iFile,iBin),FcPairNum_s2_ConInact_laseron(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1_laseron,tempdata.FCPair_s2_laseron,mouseID,dayID,RegPair,Reg,'ConInact',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_InconAct_laseron(iFile,iBin),FcPairNum_s2_InconAct_laseron(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1_laseron,tempdata.FCPair_s2_laseron,mouseID,dayID,RegPair,Reg,'InconAct',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_InconInact_laseron(iFile,iBin),FcPairNum_s2_InconInact_laseron(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1_laseron,tempdata.FCPair_s2_laseron,mouseID,dayID,RegPair,Reg,'InconInact',ShownBaseLen,SampOdorLen,DelayLen,iBin);
            [FcPairNum_s1_nonmemory_laseron(iFile,iBin),FcPairNum_s2_nonmemory_laseron(iFile,iBin)] = CountFCPairTwoTrials(tempdata.FCPair_s1_laseron,tempdata.FCPair_s2_laseron,mouseID,dayID,RegPair,Reg,'nonmemory',ShownBaseLen,SampOdorLen,DelayLen,iBin);
        end
    end
end

%% Step5: Concatenate S1 & S2 FC pair matrix, assign to FCdensity struct
if IsNoLaserMode
    for cat = catNames
        c = cat{1};
        eval(sprintf('FCdensity.PairNum_%s = repmat(PairNum_%s,1,2);',c,c));
        eval(sprintf('FCdensity.FcPairNum_%s = horzcat(FcPairNum_s1_%s,FcPairNum_s2_%s);',c,c,c));
    end
    % Compute FC density
    FCdensity.Density_ConAct = CalculateSessionBasedFcDensity(FCdensity.PairNum_ConAct,FCdensity.FcPairNum_ConAct,PairsNumthres,BinNumCriteria);
    FCdensity.Density_ConInact = CalculateSessionBasedFcDensity(FCdensity.PairNum_ConInact,FCdensity.FcPairNum_ConInact,PairsNumthres,BinNumCriteria);
    FCdensity.Density_InconAct = CalculateSessionBasedFcDensity(FCdensity.PairNum_InconAct,FCdensity.FcPairNum_InconAct,PairsNumthres,BinNumCriteria);
    FCdensity.Density_InconInact = CalculateSessionBasedFcDensity(FCdensity.PairNum_InconInact,FCdensity.FcPairNum_InconInact,PairsNumthres,BinNumCriteria);
    FCdensity.Density_nonmemory = CalculateSessionBasedFcDensity(FCdensity.PairNum_nonmemory,FCdensity.FcPairNum_nonmemory,PairsNumthres,BinNumCriteria);
    % Save result
    saveName = sprintf('SessionBased FC density_%s_PairsNumThres %d BinNumThres %d_%s_%s',binsize,PairsNumthres,BinNumCriteria,Reg,Group);
    save(fullfile(workpath,saveName),'FCdensity','-v7.3');
else
    for cat = catNames
        c = cat{1};
        eval(sprintf('FCdensity.laseron.PairNum_%s = repmat(PairNum_%s_laseron,1,2);',c,c));
        eval(sprintf('FCdensity.laseroff.PairNum_%s = repmat(PairNum_%s_laseroff,1,2);',c,c));
        eval(sprintf('FCdensity.laseron.FcPairNum_%s = horzcat(FcPairNum_s1_%s_laseron,FcPairNum_s2_%s_laseron);',c,c,c));
        eval(sprintf('FCdensity.laseroff.FcPairNum_%s = horzcat(FcPairNum_s1_%s_laseroff,FcPairNum_s2_%s_laseroff);',c,c,c));
    end
    % Compute FC density (laser on vs off comparison function)
    FCdensity.Density_ConAct = CalculateSessionBasedFcDensity(...
        FCdensity.laseroff.PairNum_ConAct,FCdensity.laseroff.FcPairNum_ConAct,...
        PairsNumthres,BinNumCriteria,FCdensity.laseron.PairNum_ConAct,FCdensity.laseron.FcPairNum_ConAct);
    FCdensity.Density_ConInact = CalculateSessionBasedFcDensity(...
        FCdensity.laseroff.PairNum_ConInact,FCdensity.laseroff.FcPairNum_ConInact,...
        PairsNumthres,BinNumCriteria,FCdensity.laseron.PairNum_ConInact,FCdensity.laseron.FcPairNum_ConInact);
    FCdensity.Density_InconAct = CalculateSessionBasedFcDensity(...
        FCdensity.laseroff.PairNum_InconAct,FCdensity.laseroff.FcPairNum_InconAct,...
        PairsNumthres,BinNumCriteria,FCdensity.laseron.PairNum_InconAct,FCdensity.laseron.FcPairNum_InconAct);
    FCdensity.Density_InconInact = CalculateSessionBasedFcDensity(...
        FCdensity.laseroff.PairNum_InconInact,FCdensity.laseroff.FcPairNum_InconInact,...
        PairsNumthres,BinNumCriteria,FCdensity.laseron.PairNum_InconInact,FCdensity.laseron.FcPairNum_InconInact);
    FCdensity.Density_nonmemory = CalculateSessionBasedFcDensity(...
        FCdensity.laseroff.PairNum_nonmemory,FCdensity.laseroff.FcPairNum_nonmemory,...
        PairsNumthres,BinNumCriteria,FCdensity.laseron.PairNum_nonmemory,FCdensity.laseron.FcPairNum_nonmemory);
    % Save laser comparison result
    saveName = sprintf('SessionBased FC density between laser off and on in %s',Reg);
    save(fullfile(workpath,saveName),'FCdensity','-v7.3');
    % Mixed repeated measure ANOVA
    Data = horzcat({num2cell(FCdensity.Density_ConAct,1)},{num2cell(FCdensity.Density_ConInact,1)},{num2cell(FCdensity.Density_InconAct,1)},{num2cell(FCdensity.Density_InconInact,1)},{num2cell(FCdensity.Density_nonmemory,1)});
    PfileName = sprintf('P value for comparing FC density between laser off and on in %s',Reg);
    Ps = GetDataMatrixForMixedRepeatedAnova(Data,fullfile(workpath,PfileName));
    % Plot figure
    figure('OuterPosition',[219 303 534 420],'Renderer','Painters');
    Xstart = 1.1;
    for iType = 1:numel(Data)
        for iGroup = 1:numel(Data{iType})
            plotBarAndError(Colorset{iGroup},Xstart,Data{iType}{iGroup},1);
            arrayfun(@(x) plot(Xstart,Data{iType}{iGroup}(x),'linestyle','none','marker','o','markerfacecolor',Colorset{iGroup},'markeredgecolor','none'),1:numel(Data{iType}{iGroup}));
            if iGroup < numel(Data{iType})
                Xstart = Xstart + 0.8;
            end
        end
        temp = cell2mat(Data{iType});
        arrayfun(@(x) plot(Xstart-0.8*(numel(Data{iType})-1):0.8:Xstart,temp(x,:),'k','marker','none'),1:size(temp,1));
        if iType < numel(Data)
            Xstart = Xstart + 1.2;
        end
    end
    SetXYaxisProperty([],[],[],0.3,Xstart+0.8,[],0,0.1,1,0,1,'FC density (%)',12,12); box off;
    saveas(gcf,fullfile(workpath,sprintf('FC density comparison between laser off and on in %s',Reg)),'fig');
    close;
end

%% ===================== SUBFUNCTION 1: Count congruent active neuron pairs =====================
function count = CountConActPair(Pair,MouseID,DayID,RegPair,BaselineLength,SampleOdorLength,DelayLength,BinID)
halfPos = size(Pair.preference,2)/2;
mask = (Pair.mouse==MouseID) & (Pair.learningday==DayID) & ismember(Pair.reg,RegPair,'rows');
% Exclude switched neurons
excludeMask = ~((any(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==2,2))...
    | (any(Pair.preference(:,halfPos+BaselineLength+SampleOdorLength+1:halfPos+BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(Pair.preference(:,halfPos+BaselineLength+SampleOdorLength+1:halfPos+BaselineLength+SampleOdorLength+DelayLength)==2,2)));
% Congruent active condition: same preference >0 in current bin
pref1 = Pair.preference(:,BaselineLength+SampleOdorLength+BinID);
pref2 = Pair.preference(:,halfPos+BaselineLength+SampleOdorLength+BinID);
conActMask = (pref1 == pref2) & (pref1 > 0);
totalMask = mask & excludeMask & conActMask;
count = nnz(totalMask);
end

%% ===================== SUBFUNCTION 2: Count congruent inactive neuron pairs =====================
function count = CountConInactPair(Pair,MouseID,DayID,RegPair,BaselineLength,SampleOdorLength,DelayLength,BinID)
halfCol = size(Pair.preference,2)/2;
mask = (Pair.mouse==MouseID) & (Pair.learningday==DayID) & ismember(Pair.reg,RegPair,'rows');
excludeMask = ~((any(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==2,2))...
    | (any(Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength)==2,2)));
pref1 = Pair.preference(:,BaselineLength+SampleOdorLength+BinID);
pref2 = Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+BinID);
max1 = max(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength),[],2);
max2 = max(Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength),[],2);
conInactMask = (pref1 .* pref2 == 0) & (max1 == max2) & (max1 > 0);
totalMask = mask & excludeMask & conInactMask;
count = nnz(totalMask);
end

%% ===================== SUBFUNCTION 3: Count incongruent active neuron pairs =====================
function count = CountInconActPair(Pair,MouseID,DayID,RegPair,BaselineLength,SampleOdorLength,DelayLength,BinID)
halfCol = size(Pair.preference,2)/2;
mask = (Pair.mouse==MouseID) & (Pair.learningday==DayID) & ismember(Pair.reg,RegPair,'rows');
excludeMask = ~((any(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==2,2))...
    | (any(Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength)==2,2)));
pref1 = Pair.preference(:,BaselineLength+SampleOdorLength+BinID);
pref2 = Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+BinID);
max1 = max(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength),[],2);
max2 = max(Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength),[],2);
inconActMask = (pref1 .* pref2 > 0) & (max1 ~= max2);
totalMask = mask & excludeMask & inconActMask;
count = nnz(totalMask);
end

%% ===================== SUBFUNCTION 4: Count incongruent inactive neuron pairs =====================
function count = CountInconInactPair(Pair,MouseID,DayID,RegPair,BaselineLength,SampleOdorLength,DelayLength,BinID)
halfCol = size(Pair.preference,2)/2;
mask = (Pair.mouse==MouseID) & (Pair.learningday==DayID) & ismember(Pair.reg,RegPair,'rows');
excludeMask = ~((any(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==2,2))...
    | (any(Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength)==2,2)));
pref1 = Pair.preference(:,BaselineLength+SampleOdorLength+BinID);
pref2 = Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+BinID);
max1 = max(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength),[],2);
max2 = max(Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength),[],2);
inconInactMask = (pref1 .* pref2 == 0) & (max1 ~= max2) & (max1>0) & (max2>0);
totalMask = mask & excludeMask & inconInactMask;
count = nnz(totalMask);
end

%% ===================== SUBFUNCTION 5: Count non-memory neuron pairs =====================
function count = CountNonMemPair(Pair,MouseID,DayID,RegPair,BaselineLength,SampleOdorLength,DelayLength)
halfCol = size(Pair.preference,2)/2;
mask = (Pair.mouse==MouseID) & (Pair.learningday==DayID) & ismember(Pair.reg,RegPair,'rows');
nonMemMask = all(Pair.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==0,2) & all(Pair.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength)==0,2);
totalMask = mask & nonMemMask;
count = nnz(totalMask);
end

%% ===================== SUBFUNCTION 6: Count S1 & S2 FC pairs with region direction filter =====================
function [S1FCpairCount,S2FCpairCount] = CountFCPairTwoTrials(FCPairS1,FCPairS2,MouseID,DayID,RegPair,Reg,Type,BaselineLength,SampleOdorLength,DelayLength,BinID)
halfCol = size(FCPairS1.preference,2)/2;
% Base mask for mouse-day-region
baseMaskS1 = (FCPairS1.mouse==MouseID) & (FCPairS1.learningday==DayID) & ismember(FCPairS1.reg,RegPair,'rows');
baseMaskS2 = (FCPairS2.mouse==MouseID) & (FCPairS2.learningday==DayID) & ismember(FCPairS2.reg,RegPair,'rows');
% Exclude dual-preference neurons
excludeMaskS1 = ~((any(FCPairS1.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(FCPairS1.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==2,2))...
    | (any(FCPairS1.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(FCPairS1.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength)==2,2)));
excludeMaskS2 = ~((any(FCPairS2.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(FCPairS2.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==2,2))...
    | (any(FCPairS2.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength)==1,2)&any(FCPairS2.preference(:,halfCol+BaselineLength+SampleOdorLength+1:halfCol+BaselineLength+SampleOdorLength+DelayLength)==2,2)));
% Category specific mask
[catMaskS1,catMaskS2] = GetCategoryMask(FCPairS1,FCPairS2,Type,BaselineLength,SampleOdorLength,DelayLength,BinID,halfCol);
% Combine masks
fullMaskS1 = baseMaskS1 & excludeMaskS1 & catMaskS1;
fullMaskS2 = baseMaskS2 & excludeMaskS2 & catMaskS2;
% Region direction AI filter for cross-region pairs
if strcmp(Reg,'mPFC-aAIC')
    dirMaskS1 = ((FCPairS1.reg(:,1)>FCPairS1.reg(:,2))&FCPairS1.AI>0)|((FCPairS1.reg(:,1)<FCPairS1.reg(:,2))&FCPairS1.AI<0);
    dirMaskS2 = ((FCPairS2.reg(:,1)>FCPairS2.reg(:,2))&FCPairS2.AI>0)|((FCPairS2.reg(:,1)<FCPairS2.reg(:,2))&FCPairS2.AI<0);
elseif strcmp(Reg,'aAIC-mPFC')
    dirMaskS1 = ((FCPairS1.reg(:,1)>FCPairS1.reg(:,2))&FCPairS1.AI<0)|((FCPairS1.reg(:,1)<FCPairS1.reg(:,2))&FCPairS1.AI>0);
    dirMaskS2 = ((FCPairS2.reg(:,1)>FCPairS2.reg(:,2))&FCPairS2.AI<0)|((FCPairS2.reg(:,1)<FCPairS2.reg(:,2))&FCPairS2.AI>0);
else
    dirMaskS1 = true(size(fullMaskS1));
    dirMaskS2 = true(size(fullMaskS2));
end
S1FCpairCount = nnz(fullMaskS1 & dirMaskS1);
S2FCpairCount = nnz(fullMaskS2 & dirMaskS2);
end

%% ===================== SUBFUNCTION 7: Generate category preference mask for FC pairs =====================
function [maskS1,maskS2] = GetCategoryMask(FCPairS1,FCPairS2,Type,BaselineLength,SampleOdorLength,DelayLength,BinID,HalfPos)
prefS1_Unit1 = FCPairS1.preference(:,BaselineLength+SampleOdorLength+BinID);
prefS1_Unit2 = FCPairS1.preference(:,HalfPos+BaselineLength+SampleOdorLength+BinID);
maxS1_Unit1 = max(FCPairS1.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength),[],2);
maxS1_Unit2 = max(FCPairS1.preference(:,HalfPos+BaselineLength+SampleOdorLength+1:HalfPos+BaselineLength+SampleOdorLength+DelayLength),[],2);
prefS2_Unit1 = FCPairS2.preference(:,BaselineLength+SampleOdorLength+BinID);
prefS2_Unit2 = FCPairS2.preference(:,HalfPos+BaselineLength+SampleOdorLength+BinID);
maxS2_Unit1 = max(FCPairS2.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength),[],2);
maxS2_Unit2 = max(FCPairS2.preference(:,HalfPos+BaselineLength+SampleOdorLength+1:HalfPos+BaselineLength+SampleOdorLength+DelayLength),[],2);

switch Type
    case 'ConAct'
        maskS1 = (prefS1_Unit1 == prefS1_Unit2) & (prefS1_Unit1 > 0);
        maskS2 = (prefS2_Unit1 == prefS2_Unit2) & (prefS2_Unit1 > 0);
    case 'ConInact'
        maskS1 = (prefS1_Unit1 .* prefS1_Unit2 == 0) & (maxS1_Unit1 == maxS1_Unit2) & (maxS1_Unit1 > 0);
        maskS2 = (prefS2_Unit1 .* prefS2_Unit2 == 0) & (maxS2_Unit1 == maxS2_Unit2) & (maxS2_Unit1 > 0);
    case 'InconAct'
        maskS1 = (prefS1_Unit1 .* prefS1_Unit2 > 0) & (maxS1_Unit1 ~= maxS1_Unit2);
        maskS2 = (prefS2_Unit1 .* prefS2_Unit2 > 0) & (maxS2_Unit1 ~= maxS2_Unit2);
    case 'InconInact'
        maskS1 = (prefS1_Unit1 .* prefS1_Unit2 == 0) & (maxS1_Unit1 ~= maxS1_Unit2) & (maxS1_Unit1>0) & (maxS1_Unit2>0);
        maskS2 = (prefS2_Unit1 .* prefS2_Unit2 == 0) & (maxS2_Unit1 ~= maxS2_Unit2) & (maxS2_Unit1>0) & (maxS2_Unit2>0);
    case 'nonmemory'
        maskS1 = all(FCPairS1.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==0,2) & all(FCPairS1.preference(:,HalfPos+BaselineLength+SampleOdorLength+1:HalfPos+BaselineLength+SampleOdorLength+DelayLength)==0,2);
        maskS2 = all(FCPairS2.preference(:,BaselineLength+SampleOdorLength+1:BaselineLength+SampleOdorLength+DelayLength)==0,2) & all(FCPairS2.preference(:,HalfPos+BaselineLength+SampleOdorLength+1:HalfPos+BaselineLength+SampleOdorLength+DelayLength)==0,2);
end
end

function FcDensity = CalculateSessionBasedFcDensity(TotalPairsNumberPerSecond, FcPairsNumberPerSecond, PairsNumberThreshold, BinNumberCriteria, varargin)
% Computes functional connectivity density for sessions
%
% Syntax:
%   1. 'No laser' mode:
%      FcDensity = CalculateSessionBasedFcDensity(TotalPairsNumber, FcPairsNumber, threshold, binCriteria)
%
%   2. 'Laser on off' mode:
%      FcDensity = CalculateSessionBasedFcDensity(TotalPairsOffNumber, FcPairsOffNumber, threshold, binCriteria, TotalPairsOnNumber, FcPairsOnNumber)
%
% Inputs:
%   TotalPairsNumberPerSecond  - Total pairs number [sessions x time_bins]
%   FcPairsNumberPerSecond        - FC pairs number [sessions x time_bins]
%   PairsNumberThreshold           - Minimum number of pairs threshold for valid bins
%   BinNumCriteria          - Minimum number of valid bins per session
%   TotalPairsNumberPerSecond_laseron (optional) - Laser-on total pairs number [sessions x time_bins]
%   FcPairsNumberPerSecond_laseron (optional)       - Laser-on FC pairs number [sessions x time_bins]
%
% Output:
%   FcDensity - Density values [sessions x 1] ('No laser' mode) or [sessions x 2] ('Laser on off' mode: col1=off, col2=on)

% Initialize output
FcDensity = [];

% Determine mode (single vs laser on/off)
isLaserMode = (nargin == 6);

% Validate input dimensions for laser mode
if isLaserMode
    TotalPairsNumberPerSecond_laseron = varargin{1};
    FcPairsNumberPerSecond_laseron = varargin{2};

    % Check dimension consistency for laser on/off data
    if ~isequal(size(TotalPairsNumberPerSecond), size(TotalPairsNumberPerSecond_laseron)) || ...
            ~isequal(size(FcPairsNumberPerSecond), size(FcPairsNumberPerSecond_laseron))
        error('Laser-on data must have identical dimensions to laser-off data');
    end
end

% Get number of sessions
numSessions = size(TotalPairsNumberPerSecond, 1);

% Process each session
for iSess = 1:numSessions
    TarBinID = find(TotalPairsNumberPerSecond(iSess, :) >= PairsNumberThreshold);

    if length(TarBinID) < BinNumberCriteria
        continue;
    end

    % Calculate density
    density = mean(FcPairsNumberPerSecond(iSess, TarBinID) ./ TotalPairsNumberPerSecond(iSess, TarBinID));

    % Handle 'No laser' mode
    if ~isLaserMode
        FcDensity(end+1, 1) = density;
        continue;
    end

    % Handle 'Laser on off' mode (additional laser-on processing)
    TarBinID_laseron = find(TotalPairsNumberPerSecond_laseron(iSess, :) >= PairsNumberThreshold);

    % Skip if laser-on doesn't meet bin criteria
    if length(TarBinID_laseron) < BinNumberCriteria
        continue;
    end

    % Calculate laser-on density and store both values
    density_laseron = mean(FcPairsNumberPerSecond_laseron(iSess, TarBinID_laseron) ./ TotalPairsNumberPerSecond_laseron(iSess, TarBinID_laseron));
    FcDensity(end+1, :) = [density, density_laseron];
end
end