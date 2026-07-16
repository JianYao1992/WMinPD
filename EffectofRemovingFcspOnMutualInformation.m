%% Effect of removing FCSP events on STM-encoding ability of following neurons

clear; clc; close all;

%% ==================== Mode Selection ====================
Mode = 'No laser';  % 'No laser' or 'Laser on off'

%% ==================== Common Parameters ====================
addpath(genpath('/home/yaojian/Codes/Function'));
addpath(genpath('/home/yaojian/Codes/CrossCorrelogram'));

Reg = {'mPFC-mPFC','aAIC-aAIC','mPFC-aAIC','aAIC-mPFC'};
binsize = '2msbin';
latency = '10ms';
AIcriteria = 0;
IsSemOrCiPlot = 1;  % 1: SEM; 2: 95% CI
color = {[1 0 0],[0 0 0]};
ShownBaseLen = 1;
SampOdorLen = 1;
MaxLuNum = 6;
NumThres_FCpair = 5;

%% ==================== Mode-Specific Parameters ====================
IsRemoveFCSP = 1;           % 0: remove NonFCSP; 1: remove FCSP; 2: remove shuffled FCSP
SamplingTimes = 100;
if strcmp(Mode, 'No laser')
    Group = 'Healthy';
    BaseLen = 13;
    DelayLen = 10;
    workpath = fullfile('/home/yaojian/NoLaserinODPA', Group, 'Training');
else
    BaseLen = 8;
    DelayLen = 6;
    workpath = '/home/yaojian/LaserActivationOnOffinODPA/Training';
end
DelayBinID = 1:1:DelayLen;
TestOdorLen = 1;

%% ==================== Load Units Information ====================
if strcmp(Mode, 'No laser')
    conditions = {'default'};
    fprintf('//////////Loading units information of %s group//////////\n', Group);
    UnitsInfo = load(fullfile(workpath, sprintf('UnitsInformation_%s.mat', Group)));
else
    conditions = {'laseroff','laseron'};
    fprintf('//////////Loading units information//////////\n');
    UnitsInfo = load(fullfile(workpath, 'UnitsInformation_LaserOnOff.mat'));
end
UnitsInformation = UnitsInfo.UnitsInformation;
fprintf('**********Units information loaded**********\n');


%% ==================== Initialize Results Structure ====================
eit = struct('mPFCmPFC',[],'aAICaAIC',[],'mPFCaAIC',[],'aAICmPFC',[]);

%% ==================== Process Each Region ====================
for iReg = 1:numel(Reg)
    fprintf('Processing region: %s\n', Reg{iReg});

    % Initialize FC pair storage
    FCPairs = initFCPairs(Mode);

    % Process each delay bin
    for iBin = 1:numel(DelayBinID)
        % Load FC information for current delay-period bin
        if strcmp(Mode, 'No laser')
            data = load(fullfile(workpath, sprintf('FCinformation_%s_%d_%d_%s.mat', ...
                binsize, DelayBinID(iBin), DelayBinID(iBin)+1, Group)));
        else
            data = load(fullfile(workpath, sprintf('FCinformation_%s_%d_%d_LaserOnOff.mat', ...
                binsize, DelayBinID(iBin), DelayBinID(iBin)+1)));
        end

        % Process each condition (laseroff/laseron)
        for Idx = 1:numel(conditions)
            cond = conditions{Idx};
            [fc_s1, fc_s2] = getFCPairData(data, Mode, cond);

            % Filter by target brain region
            fc_s1 = filterByRegion(fc_s1, Reg{iReg}, AIcriteria);
            fc_s2 = filterByRegion(fc_s2, Reg{iReg}, AIcriteria);

            % Align direction (leading -> following)
            fc_s1 = alignDirection(fc_s1, ShownBaseLen, SampOdorLen, DelayLen, TestOdorLen);
            fc_s2 = alignDirection(fc_s2, ShownBaseLen, SampOdorLen, DelayLen, TestOdorLen);

            % Classify pairs into memory-to-memory and non-memory-to-memory
            [pairswithmemLU_s1, pairswithnonmemLU_s1] = classifyPairs(fc_s1, DelayBinID(iBin), ShownBaseLen, SampOdorLen);
            [pairswithmemLU_s2, pairswithnonmemLU_s2] = classifyPairs(fc_s2, DelayBinID(iBin), ShownBaseLen, SampOdorLen);

            % Group by number of leading neurons
            FCPairs = accumulateFCPairs(FCPairs, cond, pairswithmemLU_s1, pairswithmemLU_s2, ...
                pairswithnonmemLU_s1, pairswithnonmemLU_s2, DelayBinID(iBin), MaxLuNum);
        end
    end

    % Analyze results for each condition
    allResults = struct();
    for Idx = 1:numel(conditions)
        cond = conditions{Idx};
        allResults.(cond) = analyzeCondition(FCPairs, cond, UnitsInformation, ...
            BaseLen, SampOdorLen, IsRemoveFCSP, SamplingTimes, NumThres_FCpair, ...
            IsSemOrCiPlot, color, workpath, binsize, latency, Reg{iReg});
    end

    % Store results in the eit structure
    storeResults(eit, Reg{iReg}, allResults, Mode, IsSemOrCiPlot);

    fprintf('********************Region-%s finished********************\n', Reg{iReg});
end

%% ==================== Save Results ====================
if strcmp(Mode, 'No laser')
    if IsRemoveFCSP == 0
        save(fullfile(workpath, sprintf('Decreased FU MI with removing NonFCSP-%s-%s-%s.mat', ...
            binsize, latency, Group)), 'eit', '-v7.3');
    elseif IsRemoveFCSP == 1
        save(fullfile(workpath, sprintf('Decreased FU MI with removing FCSP-%s-%s-%s.mat', ...
            binsize, latency, Group)), 'eit', '-v7.3');
    elseif IsRemoveFCSP == 2
        save(fullfile(workpath, sprintf('Decreased FU MI with removing ShufFCSP-%s-%s-%s.mat', ...
            binsize, latency, Group)), 'eit', '-v7.3');
    end
else
    save(fullfile(workpath, sprintf('Decreased FU MI with removing FCSP-%s-%s-LaserOnOff.mat', binsize, latency)), 'eit', '-v7.3');
end


% ============================================================================
% Helper Functions
% ============================================================================

function FCPairs = initFCPairs(Mode)
FCPairs = struct();
if strcmp(Mode, 'No laser')
    FCPairs.memtomem.s1 = [];
    FCPairs.memtomem.s2 = [];
    FCPairs.nonmemtomem.s1 = [];
    FCPairs.nonmemtomem.s2 = [];
else
    conditions = {'laseroff', 'laseron'};
    for i = 1:numel(conditions)
        cond = conditions{i};
        FCPairs.memtomem.(cond).s1 = [];
        FCPairs.memtomem.(cond).s2 = [];
        FCPairs.nonmemtomem.(cond).s1 = [];
        FCPairs.nonmemtomem.(cond).s2 = [];
    end
end
end

function [fc_s1, fc_s2] = getFCPairData(data, Mode, condition)
if strcmp(Mode, 'No laser')
    fc_s1 = data.FCPair_s1;
    fc_s2 = data.FCPair_s2;
else
    fc_s1 = data.(sprintf('FCPair_s1_%s', condition));
    fc_s2 = data.(sprintf('FCPair_s2_%s', condition));
end
end

function fc = filterByRegion(fc, region, AIcriteria)
switch region
    case 'mPFC-mPFC'
        isTarget = (all(fc.reg==3,2) | all(fc.reg==4,2)) & abs(fc.AI) > AIcriteria;
    case 'aAIC-aAIC'
        isTarget = (all(fc.reg==1,2) | all(fc.reg==2,2)) & abs(fc.AI) > AIcriteria;
    case 'mPFC-aAIC'
        isTarget = (ismember(fc.reg,[1 3; 2 4],'rows') & fc.AI < -1*AIcriteria) | ...
            (ismember(fc.reg,[3 1; 4 2],'rows') & fc.AI > AIcriteria);
    case 'aAIC-mPFC'
        isTarget = (ismember(fc.reg,[1 3; 2 4],'rows') & fc.AI > AIcriteria) | ...
            (ismember(fc.reg,[3 1; 4 2],'rows') & fc.AI < -1*AIcriteria);
end

fc.mouse = fc.mouse(isTarget);
fc.learningday = fc.learningday(isTarget);
fc.reg = fc.reg(isTarget,:);
fc.unitsid = fc.unitsid(isTarget,:);
fc.AI = fc.AI(isTarget);
fc.FR = fc.FR(isTarget,:);
fc.preference = fc.preference(isTarget,:);
end

function fc = alignDirection(fc, BaselineLength, SampleOdorLength, DelayLength, TestOdorLength)
% Align FC pairs so AI is positive (leading -> following direction)
for iPair = 1:size(fc.unitsid, 1)
    if fc.AI(iPair) < 0
        fc.reg(iPair,:) = fliplr(fc.reg(iPair,:));
        fc.unitsid(iPair,:) = fliplr(fc.unitsid(iPair,:));
        fc.AI(iPair) = -1 * fc.AI(iPair);
        fc.FR(iPair,:) = fliplr(fc.FR(iPair,:));
        flipIdx = BaselineLength + SampleOdorLength + DelayLength + TestOdorLength;
        fc.preference(iPair,:) = horzcat(fc.preference(iPair,flipIdx+1:end), fc.preference(iPair,1:flipIdx));
    end
end
end

function [PairsWithMemLU, PairsWithNonmemLU] = classifyPairs(fc, BinID, BaselineLength, SampleOdorLength)
% Classify FC pairs into memory-to-memory and non-memory-to-memory
prefIdx = BaselineLength + SampleOdorLength + BinID;
halfLen = size(fc.preference, 2) / 2;

isMemToMem = fc.preference(:,prefIdx) > 0 & fc.preference(:,prefIdx + halfLen) > 0;
PairsWithMemLU = horzcat(fc.unitsid(isMemToMem,:), fc.mouse(isMemToMem,:), ...
    fc.learningday(isMemToMem,:), fc.AI(isMemToMem,:), fc.FR(isMemToMem,:));

isNonMemToMem = fc.preference(:,prefIdx) == 0 & fc.preference(:,prefIdx + halfLen) > 0;
PairsWithNonmemLU = horzcat(fc.unitsid(isNonMemToMem,:), fc.mouse(isNonMemToMem,:), ...
    fc.learningday(isNonMemToMem,:), fc.AI(isNonMemToMem,:), fc.FR(isNonMemToMem,:));
end

function FCPairs = accumulateFCPairs(FCPairs, condition, PairsWithMemoryLU_s1, PairsWithMemoryLU_s2, PairsWithNonmemoryLU_s1, PairsWithNonmemoryLU_s2, BinID, MaxLeadingUnitNumber)
% Group FC pairs by leading neuron count and accumulate across delay-period bins
if strcmp(condition,'default')
    FCPairs.memtomem.s1 = [FCPairs.memtomem.s1; GetPairAlignedWithUniqueFu(PairsWithMemoryLU_s1, BinID, MaxLeadingUnitNumber)];
    FCPairs.memtomem.s2 = [FCPairs.memtomem.s2; GetPairAlignedWithUniqueFu(PairsWithMemoryLU_s2, BinID, MaxLeadingUnitNumber)];
    FCPairs.nonmemtomem.s1 = [FCPairs.nonmemtomem.s1; GetPairAlignedWithUniqueFu(PairsWithNonmemoryLU_s1, BinID, MaxLeadingUnitNumber)];
    FCPairs.nonmemtomem.s2 = [FCPairs.nonmemtomem.s2; GetPairAlignedWithUniqueFu(PairsWithNonmemoryLU_s2, BinID, MaxLeadingUnitNumber)];
else
    FCPairs.memtomem.(condition).s1 = [FCPairs.memtomem.(condition).s1; GetPairAlignedWithUniqueFu(PairsWithMemoryLU_s1, BinID, MaxLeadingUnitNumber)];
    FCPairs.memtomem.(condition).s2 = [FCPairs.memtomem.(condition).s2; GetPairAlignedWithUniqueFu(PairsWithMemoryLU_s2, BinID, MaxLeadingUnitNumber)];
    FCPairs.nonmemtomem.(condition).s1 = [FCPairs.nonmemtomem.(condition).s1; GetPairAlignedWithUniqueFu(PairsWithNonmemoryLU_s1, BinID, MaxLeadingUnitNumber)];
    FCPairs.nonmemtomem.(condition).s2 = [FCPairs.nonmemtomem.(condition).s2; GetPairAlignedWithUniqueFu(PairsWithNonmemoryLU_s2, BinID, MaxLeadingUnitNumber)];
end
end

% ============================================================================
% Core FC Analysis Functions
% ============================================================================

function TargetPair = GetPairAlignedWithUniqueFu(CouplingPair, BinID, MaxLeadingUnitNumber)
FCpair = cell(1, MaxLeadingUnitNumber);
UniqFollowingUnit = unique(CouplingPair(:, 2), 'stable');

for iFU = 1:numel(UniqFollowingUnit)
    tempLUnum = nnz(CouplingPair(:, 2) == UniqFollowingUnit(iFU));
    for iLUnumber = 1:tempLUnum
        if iLUnumber <= MaxLeadingUnitNumber
            FCpair{iLUnumber}{end+1, 1} = horzcat(BinID * ones(tempLUnum, 1), ...
                CouplingPair(CouplingPair(:, 2) == UniqFollowingUnit(iFU), :));
        end
    end
end

TargetPair = cell(size(FCpair));
for i = 1:numel(FCpair)
    for j = 1:size(FCpair{i}, 1)
        temp = nchoosek(1:size(FCpair{i}{j}, 1), i);
        for k = 1:size(temp, 1)
            TargetPair{i}{end+1, 1} = FCpair{i}{j}(temp(k, :), :);
        end
    end
end
end

function SumFCpair = SumFCofDelayBins(FCpair)
% Concatenate FC pairs across delay bins
SumFCpair = cell(1, size(FCpair, 2));
for i = 1:size(FCpair, 2)
    temp = FCpair(:, i);
    SumFCpair{i} = vertcat(temp{:});
end
end

function [UniqueFC, MaximalFR, MaxInMinAIEachCondition] = GetNonOverlapFC(FCpair)
% Remove overlapping FC pairs
UniqueFC = cell(1, size(FCpair, 2));
MaximalFR = cell(1, size(FCpair, 2));
MaxInMinAIEachCondition = cell(1, size(FCpair, 2));

for i = 1:size(FCpair, 2)
    temp = FCpair(:, i);
    temp = vertcat(temp{:});

    for j = 1:size(temp, 1)
        CurrFC = temp{j}(:, 1:end-3);
        id = [];

        for k = 1:size(UniqueFC{i}, 1)
            compareFC = UniqueFC{i}{k};
            if isequal(CurrFC, compareFC)
                id = [id k];
            end
        end

        if isempty(id)
            UniqueFC{i} = [UniqueFC{i}; {CurrFC}];
            MaximalFR{i} = [MaximalFR{i}; max(temp{j}(:, end-1))];
            MaxInMinAIEachCondition{i} = [MaxInMinAIEachCondition{i}; min(temp{j}(:, end-2))];
        else
            MaximalFR{i}(id) = max(horzcat(max(temp{j}(:, end-1)), MaximalFR{i}(id)));
            MaxInMinAIEachCondition{i}(id) = max(horzcat(min(temp{j}(:, end-2)), MaxInMinAIEachCondition{i}(id)));
        end
    end
end
end

% ============================================================================
% Analysis and Plotting
% ============================================================================

function result = analyzeCondition(FCPairs, condition, UnitsInformation, ...
    BaselineLength, SampleOdorLength, IsRemoveFCSP, SamplingTimes, NumberThreshold_FCpair, ...
    IsSemOrCiPlot, color, path, binsize, latency, region)

% Build FC pair structures for this condition
FCpair_MemLU = buildFCPairStructure(FCPairs.memtomem, condition);
FCpair_NonmemLU = buildFCPairStructure(FCPairs.nonmemtomem, condition);

% Get unique FC pairs
[UniqFC_MemLU, MaxFR_MemLU, AI_MemLU] = GetNonOverlapFC(FCpair_MemLU);
[UniqFC_NonmemLU, MaxFR_NonmemLU, AI_NonmemLU] = GetNonOverlapFC(FCpair_NonmemLU);

% Check for empty data
if isempty(UniqFC_MemLU{1}) || isempty(UniqFC_NonmemLU{1})
    result = [];
    return;
end

% Compute MI after removing FCSP
[AllFuMI_MemLU, AllFuMI_NonmemLU] = computeFUActivity(...
    condition, IsRemoveFCSP, SamplingTimes, ...
    UniqFC_MemLU, UniqFC_NonmemLU, UnitsInformation, BaselineLength, SampleOdorLength);

% Append FR and AI info
AllFuMI_MemLU = cellfun(@(x,y,z) horzcat(x,y,z), AllFuMI_MemLU, MaxFR_MemLU, AI_MemLU, 'UniformOutput', false);
AllFuMI_NonmemLU = cellfun(@(x,y,z) horzcat(x,y,z), AllFuMI_NonmemLU, MaxFR_NonmemLU, AI_NonmemLU, 'UniformOutput', false);

% Filter FC pair groups with sufficient count
[AllFuMI_MemLU, AllFuMI_NonmemLU] = ...
    filterByFCNumber(AllFuMI_MemLU, AllFuMI_NonmemLU, NumberThreshold_FCpair);

% Compute change in values
[ChangedValue_MemLU, ChangedValue_NonmemLU] = computeChangedValues(AllFuMI_MemLU, AllFuMI_NonmemLU);

% Plot results if applicable
tbl = [];
if shouldPlot(condition, IsRemoveFCSP)
    tbl = plotResults(ChangedValue_MemLU, ChangedValue_NonmemLU, ...
        IsSemOrCiPlot, color, path, binsize, latency, region, condition);
end

% Package results
result = struct(...
    'ChangedValue_memtomem', ChangedValue_MemLU, ...
    'FC_memtomem', UniqFC_MemLU, ...
    'ChangedValue_nonmemtomem', ChangedValue_NonmemLU, ...
    'FC_nonmemtomem', UniqFC_NonmemLU, ...
    'tbl', tbl ...
    );
end

function FCpair = buildFCPairStructure(Data, condition)
% Build a 2-row cell array (s1 and s2) from FC pair data
if strcmp(condition,'default')
    FCpair = cell(2, size(Data.s1, 2));
    FCpair(1,:) = SumFCofDelayBins(Data.s1);
    FCpair(2,:) = SumFCofDelayBins(Data.s2);
else
    FCpair = cell(2, size(Data.(condition).s1, 2));
    FCpair(1,:) = SumFCofDelayBins(Data.(condition).s1);
    FCpair(2,:) = SumFCofDelayBins(Data.(condition).s2);
end
end

function [ChangedValue_MemLU, ChangedValue_NonmemLU] = computeChangedValues(fuMI_MemLU, fuMI_NonmemLU)
% Compute relative change in values
ChangedValue_MemLU = cellfun(@(x) (x(:,2)-x(:,1))./x(:,1), fuMI_MemLU, 'UniformOutput', 0);
ChangedValue_MemLU = cellfun(@(x,y) horzcat(x,y), ChangedValue_MemLU, fuMI_MemLU, 'UniformOutput', 0);
ChangedValue_NonmemLU = cellfun(@(x) (x(:,2)-x(:,1))./x(:,1), fuMI_NonmemLU, 'UniformOutput', 0);
ChangedValue_NonmemLU = cellfun(@(x,y) horzcat(x,y), ChangedValue_NonmemLU, fuMI_NonmemLU, 'UniformOutput', 0);
end

function tf = shouldPlot(condition, IsRemoveFCSP)
% Determine whether to plot based on mode
if strcmp(condition, 'default')
    tf = (IsRemoveFCSP == 1);
else
    tf = true;
end
end

function [MI_MemLU, MI_NonmemLU] = computeFUActivity(condition, IsRemoveFCSP, SamplingTimes, ...
    UniqueFC_MemLU, UniqueFC_NonmemLU, UnitsInformation, BaselineLength, SampleOdorLength)
% Compute MI for all following units after removing FCSP
MI_MemLU = GetMIofAllFUsAfterRemovingFC(IsRemoveFCSP, UniqueFC_MemLU, ...
    UnitsInformation(:,11), UnitsInformation(:,10), BaselineLength, SampleOdorLength, SamplingTimes, condition);
MI_NonmemLU = GetMIofAllFUsAfterRemovingFC(IsRemoveFCSP, UniqueFC_NonmemLU, ...
    UnitsInformation(:,11), UnitsInformation(:,10), BaselineLength, SampleOdorLength, SamplingTimes, condition);
end

function [fuMI_MemLU, fuMI_NonmemLU] = ...
    filterByFCNumber(fuMI_MemLU, fuMI_NonmemLU, threshold)
% Filter FC pair groups with count below threshold
FCnum_mem = cellfun(@(x) size(x,1), fuMI_MemLU);
temp_mem = find(FCnum_mem < threshold);
if isempty(temp_mem), temp_mem = numel(FCnum_mem) + 1; end

FCnum_nonmem = cellfun(@(x) size(x,1), fuMI_NonmemLU);
temp_nonmem = find(FCnum_nonmem < threshold);
if isempty(temp_nonmem), temp_nonmem = numel(FCnum_nonmem) + 1; end

maxID = min([min(temp_mem) min(temp_nonmem)]) - 1;
fuMI_MemLU = fuMI_MemLU(:, 1:maxID);
fuMI_NonmemLU = fuMI_NonmemLU(:, 1:maxID);
end

function tbl = plotResults(ChangedValue_MemLU, ChangedValue_NonmemLU, IsSemOrCiPlot, ...
    color, workpath, binsize, latency, region, condition)
% Plot bar charts with error bars (SEM or CI)
temp_MemLU = cellfun(@(x) x(:,1), ChangedValue_MemLU, 'UniformOutput', false);
temp_NonmemLU = cellfun(@(x) x(:,1), ChangedValue_NonmemLU, 'UniformOutput', false);

figure('position',[300 200 500 300]);

if IsSemOrCiPlot == 1
    % SEM plot with two-way ANOVA
    [~, tbl, ~] = unbalanced_anova_test(temp_MemLU, temp_NonmemLU);
    for iLU = 1:size(temp_MemLU, 2)
        plotBarAndError(color{1}, 1.1+1.8*(iLU-1), temp_MemLU{iLU}, 1);
    end
    for iLU = 1:size(temp_NonmemLU, 2)
        plotBarAndError(color{2}, 1.9+1.8*(iLU-1), temp_NonmemLU{iLU}, 1);
    end
else
    % 95% CI plot with bootstrap test
    bstimes = 1000;
    bs_MemLU = cell(size(temp_MemLU));
    bs_NonmemLU = cell(size(temp_NonmemLU));

    for iLU = 1:size(temp_MemLU, 2)
        bs_MemLU{iLU} = BootstrapCalculation(temp_MemLU{iLU}, bstimes, ...
            ceil(0.95*numel(temp_MemLU{iLU})));
        plotBarAndError(color{1}, 1.1+1.8*(iLU-1), bs_MemLU{iLU}, 2);
    end
    for iLU = 1:size(temp_NonmemLU, 2)
        bs_NonmemLU{iLU} = BootstrapCalculation(temp_NonmemLU{iLU}, bstimes, ...
            ceil(0.95*numel(temp_NonmemLU{iLU})));
        plotBarAndError(color{2}, 1.9+1.8*(iLU-1), bs_NonmemLU{iLU}, 2);
    end

    for iLU = 1:size(temp_MemLU, 2)
        tempP = bstest(bs_MemLU{iLU}, bs_NonmemLU{iLU});
        text(1.5+1.8*(iLU-1), mean(bs_MemLU{iLU}), ...
            ['p = ' num2str(tempP)], 'color', 'r'); hold on
    end
    title('Bootstrap test without Bonferroni correction');
    tbl = [];
end

box on;
SetXYaxisProperty(1.5, 1.8, 1.5+1.8*(numel(temp_MemLU)-1), ...
    0.5, 2.5+1.8*(numel(temp_MemLU)-1), 'LU number', ...
    -1, 0.05, 0, -0.3, 0, 'Change of FU selectivity index (%)', 16, 16);
set(gcf, 'Render', 'Painter');

% Build filename based on condition
if strcmp(condition, 'default')
    filename = sprintf('Decreased FU MI with removing FCSP-%s-%s-%s', binsize, latency, region);
else
    filename = sprintf('Decreased FU MI with removing FCSP-%s-%s-%s-%s', binsize, latency, region, condition);
end
saveas(gcf, fullfile(workpath, filename), 'fig');
close all;
end

function storeResults(eit, region, allResults, Mode, IsSemOrCiPlot)
% Store analysis results into the eit structure
RegionName = strrep(region, '-', '');
conditions = fieldnames(allResults);

for i = 1:numel(conditions)
    cond = conditions{i};
    result = allResults.(cond);
    if isempty(result), continue; end

    if strcmp(Mode, 'No laser')
        eit.(RegionName).ChangedValue_memtomem = result.ChangedValue_memtomem;
        eit.(RegionName).FC_memtomem = result.FC_memtomem;
        eit.(RegionName).ChangedValue_nonmemtomem = result.ChangedValue_nonmemtomem;
        eit.(RegionName).FC_nonmemtomem = result.FC_nonmemtomem;
        if IsSemOrCiPlot == 1 && ~isempty(result.tbl)
            eit.(RegionName).tbl = result.tbl;
        end
    else
        eit.(RegionName).ChangedValue_memtomem.(cond) = result.ChangedValue_memtomem;
        eit.(RegionName).FC_memtomem.(cond) = result.FC_memtomem;
        eit.(RegionName).ChangedValue_nonmemtomem.(cond) = result.ChangedValue_nonmemtomem;
        eit.(RegionName).FC_nonmemtomem.(cond) = result.FC_nonmemtomem;
        if IsSemOrCiPlot == 1 && ~isempty(result.tbl)
            eit.(RegionName).tbl.(cond) = result.tbl;
        end
    end
end
end

function AllFuMI = GetMIofAllFUsAfterRemovingFC(IsToRemoveFCSP, FCpair, unitsRG, TrialMarker, BaselineLength, SampleOdorLength, RunTimes, condition)
% Compute MI for all following units based on different FCSP removal strategies
AllFuMI = cell(size(FCpair));

for i = 1:numel(FCpair)
    for j = 1:size(FCpair{i}, 1)
        fprintf('Processing %dth one of total %d FC pairs with %d leading neurons\n', j, size(FCpair{i}, 1), i);

        [data, MouseID, LearningDayID] = processFCPair(...
            FCpair{i}{j}, unitsRG, TrialMarker, condition);

        switch IsToRemoveFCSP
            case 0
                [withNonFC, withoutNonFC] = DecreaFUMIofRemoveNonFCSP(BaselineLength, SampleOdorLength, data.binID, ...
                    data.RGinS1_LU, data.RGinS2_LU, data.RGinS1_FU, data.RGinS2_FU, RunTimes);
                AllFuMI{i} = [AllFuMI{i}; horzcat(withNonFC, withoutNonFC, MouseID, LearningDayID)];
            case 1
                [withFC, withoutFC] = DecreaFUMIofRemoveFCSP(BaselineLength, SampleOdorLength, data.binID, ...
                    data.RGinS1_LU, data.RGinS2_LU, data.RGinS1_FU, data.RGinS2_FU);
                AllFuMI{i} = [AllFuMI{i}; horzcat(withFC, withoutFC, MouseID, LearningDayID)];
            case 2
                [withShufFC, withoutShufFC] = DecreaFUMIofRemoveShufFCSP(BaselineLength, SampleOdorLength, data.binID, ...
                    data.RGinS1_LU, data.RGinS2_LU, data.RGinS1_FU, data.RGinS2_FU, RunTimes);
                AllFuMI{i} = [AllFuMI{i}; horzcat(withShufFC, withoutShufFC, MouseID, LearningDayID)];
        end
    end
end
end

function [data, MouseID, LearningDayID] = processFCPair(FCpair, unitsRG, TrialMarker, condition)
ID_bin = FCpair(1, 1);
ID_LU = FCpair(:, 2);
ID_FU = FCpair(1, 3);
MouseID = FCpair(1, 4);
LearningDayID = FCpair(1, 5);

if strcmp(condition,'default')
    RG_LU = unitsRG(ID_LU, :);
    RG_LU = vertcat(RG_LU{:});
    RG_FU = unitsRG{ID_FU};

    ID_s1trials = find(TrialMarker{ID_FU}(:, 1) == 1);
    ID_s2trials = find(TrialMarker{ID_FU}(:, 1) == 2);
else
    RG_LU = unitsRG(ID_LU, :);
    NewRG_LU = [];
    for i = 1:numel(RG_LU)
        NewRG_LU = [NewRG_LU; RG_LU{i}.(condition)];
    end
    RG_LU = NewRG_LU;
    RG_FU = unitsRG{ID_FU}.(condition);

    ID_s1trials = find(TrialMarker{ID_FU}.(condition)(:, 1) == 1);
    ID_s2trials = find(TrialMarker{ID_FU}.(condition)(:, 1) == 2);
end

data = struct(...
    'binID', ID_bin, ...
    'RGinS1_LU', RG_LU(:, ID_s1trials), ...
    'RGinS2_LU', RG_LU(:, ID_s2trials), ...
    'RGinS1_FU', RG_FU(:, ID_s1trials), ...
    'RGinS2_FU', RG_FU(:, ID_s2trials) ...
    );
end

function [MI_withFC, MI_withoutFC] = DecreaFUMIofRemoveFCSP(BaselineLength, SampleOdorLength, BinID, ...
    LUspiketime_s1, LUspiketime_s2, FUspiketime_s1, FUspiketime_s2)
% Compute MI with and without FCSP events
[FR_s1, FR_s2, FR_remove_s1, FR_remove_s2] = ...
    removeFCSPfromSpikes(BaselineLength, SampleOdorLength, BinID, ...
    LUspiketime_s1, LUspiketime_s2, FUspiketime_s1, FUspiketime_s2);

MI_withFC = calcMI(FR_s1, FR_s2);
MI_withoutFC = calcMI(FR_remove_s1, FR_remove_s2);
end

function [MI_wiNonFC, MI_woNonFC] = DecreaFUMIofRemoveNonFCSP(BaseLen, SampleOdorLen, BinID, ...
    spiketime_s1_LU, spiketime_s2_LU, spiketime_s1_FU, spiketime_s2_FU, RunTimes)
% Compute MI with non-FCSP removed via resampling
[FR_s1, FR_s2, NonFcspRate_s1, NonFcspRate_s2, FcspRate_s1, FcspRate_s2] = ...
    removeFCSPandTrackRates(BaseLen, SampleOdorLen, BinID, ...
    spiketime_s1_LU, spiketime_s2_LU, spiketime_s1_FU, spiketime_s2_FU);

MI_wiNonFC = calcMI_snca(FR_s1, FR_s2);

% Parallel computation for non-FCSP removal
MI_woNonFC = zeros(RunTimes, 1);
setupParallelPool(20);

for iRun = 1:RunTimes
    f(iRun) = parfeval(@RemoveNonFcspToCalculateMI, 1, ...
        FcspRate_s1, FcspRate_s2, NonFcspRate_s1, NonFcspRate_s2, FR_s1, FR_s2);
end

for iRun = 1:RunTimes
    [~, tempMI] = fetchNext(f);
    MI_woNonFC(iRun, 1) = tempMI;
end

MI_woNonFC = mean(MI_woNonFC, 1);
end

function [MI_wiShufFC, MI_woShufFC] = DecreaFUMIofRemoveShufFCSP(BaseLen, SampleOdorLen, BinID, ...
    spiketime_s1_LU, spiketime_s2_LU, spiketime_s1_FU, spiketime_s2_FU, RunTimes)
% Compute MI with shuffled FCSP events removed
[FR_s1, FR_s2, ~, ~, FcspRate_s1, FcspRate_s2] = ...
    removeFCSPandTrackRates(BaseLen, SampleOdorLen, BinID, ...
    spiketime_s1_LU, spiketime_s2_LU, spiketime_s1_FU, spiketime_s2_FU);

MI_wiShufFC = calcMI_snca(FR_s1, FR_s2);

% Parallel computation for shuffled FCSP removal
MI_woShufFC = zeros(RunTimes, 1);
setupParallelPool(20);

for iRun = 1:RunTimes
    f(iRun) = parfeval(@RemoveShufFcspToCalculateMI, 1, ...
        FcspRate_s1, FcspRate_s2, FR_s1, FR_s2);
end

for iRun = 1:RunTimes
    [~, tempMI] = fetchNext(f);
    MI_woShufFC(iRun, 1) = tempMI;
end

MI_woShufFC = mean(MI_woShufFC, 1);
end

% ============================================================================
% laseronoff Mode-Specific Functions
% ============================================================================

function AllFuMI = GetAUCofAllFUsAfterRemovingFC_laseronoff(FCpair, unitsRG, trialmark, BaseLen, SampleOdorLen, LaserCondition)
% Compute MI for all FUs under specific laser condition
AllFuMI = cell(size(FCpair));

for i = 1:numel(FCpair)
    for j = 1:size(FCpair{i}, 1)
        fprintf('Processing %dth one of total %d FC pairs with %d leading neurons\n', j, size(FCpair{i}, 1), i);

        ID_bin = FCpair{i}{j}(1, 1);
        ID_LU = FCpair{i}{j}(:, 2);
        ID_FU = FCpair{i}{j}(1, 3);
        ID_mice = FCpair{i}{j}(1, 4);
        ID_learningday = FCpair{i}{j}(1, 5);

        % Get spike rasters for the specific laser condition
        RG_LU = [];
        for iUnit = 1:numel(ID_LU)
            RG_LU = [RG_LU; unitsRG{ID_LU(iUnit)}.(LaserCondition)];
        end
        RG_FU = unitsRG{ID_FU}.(LaserCondition);

        ID_s1trials = find(trialmark{ID_FU}.(LaserCondition)(:, 1) == 1);
        ID_s2trials = find(trialmark{ID_FU}.(LaserCondition)(:, 1) == 2);

        [MI_wiFC, MI_woFC] = DecreaFUauROCofRemoveFCSP(BaseLen, SampleOdorLen, ID_bin, ...
            RG_LU(:, ID_s1trials), RG_LU(:, ID_s2trials), ...
            RG_FU(:, ID_s1trials), RG_FU(:, ID_s2trials));

        AllFuMI{i} = [AllFuMI{i}; horzcat(MI_wiFC, MI_woFC, ID_mice, ID_learningday)];
    end
end
end

function [MI_wiFC, MI_woFC] = DecreaFUauROCofRemoveFCSP(BaseLen, SampleOdorLen, BinID, ...
    spiketime_s1_LU, spiketime_s2_LU, spiketime_s1_FU, spiketime_s2_FU)
% Compute MI with and without FCSP (laseronoff mode)
[FR_s1, FR_s2, FR_remove_s1, FR_remove_s2] = ...
    removeFCSPfromSpikes(BaseLen, SampleOdorLen, BinID, ...
    spiketime_s1_LU, spiketime_s2_LU, spiketime_s1_FU, spiketime_s2_FU);

MI_wiFC = calcMI_snca(FR_s1, FR_s2);
MI_woFC = calcMI_snca(FR_remove_s1, FR_remove_s2);
end

% ============================================================================
% Shared Low-Level Functions
% ============================================================================

function [FR_s1, FR_s2, FR_remove_s1, FR_remove_s2] = ...
    removeFCSPfromSpikes(BaselineLength, SampleOdorLength, BinID, ...
    LUspiketime_s1, LUspiketime_s2, FUspiketime_s1, FUspiketime_s2)
% Remove FCSP-related spikes from following unit activity
FR_s1 = []; FR_s2 = []; FR_remove_s1 = []; FR_remove_s2 = [];

for iTrialType = 1:2
    if iTrialType == 1
        RG_FU = FUspiketime_s1;
        RG_LU = LUspiketime_s1;
    else
        RG_FU = FUspiketime_s2;
        RG_LU = LUspiketime_s2;
    end

    for iTrial = 1:numel(RG_FU)
        [fuCount, fuKeptCount] = processSingleTrial(...
            RG_FU(:, iTrial), RG_LU(:, iTrial), BaselineLength, SampleOdorLength, BinID);

        if iTrialType == 1
            FR_s1 = [FR_s1; fuCount];
            FR_remove_s1 = [FR_remove_s1; fuKeptCount];
        else
            FR_s2 = [FR_s2; fuCount];
            FR_remove_s2 = [FR_remove_s2; fuKeptCount];
        end
    end
end
end

function [FR_s1, FR_s2, NonFcspRate_s1, NonFcspRate_s2, FcspRate_s1, FcspRate_s2] = ...
    removeFCSPandTrackRates(BaseLen, SampleOdorLen, BinID, ...
    spiketime_s1_LU, spiketime_s2_LU, spiketime_s1_FU, spiketime_s2_FU)
% Remove FCSP spikes and separately track FCSP and non-FCSP spike rates
FR_s1 = []; FR_s2 = [];
NonFcspRate_s1 = []; NonFcspRate_s2 = [];
FcspRate_s1 = []; FcspRate_s2 = [];

for iTrialType = 1:2
    if iTrialType == 1
        RG_FU = spiketime_s1_FU;
        RG_LU = spiketime_s1_LU;
    else
        RG_FU = spiketime_s2_FU;
        RG_LU = spiketime_s2_LU;
    end

    for iTrial = 1:numel(RG_FU)
        [fuCount, fuKeptCount] = processSingleTrial(...
            RG_FU(:, iTrial), RG_LU(:, iTrial), BaseLen, SampleOdorLen, BinID);
        fcspCount = fuCount - fuKeptCount;

        if iTrialType == 1
            FR_s1 = [FR_s1; fuCount];
            NonFcspRate_s1 = [NonFcspRate_s1; fuKeptCount];
            FcspRate_s1 = [FcspRate_s1; fcspCount];
        else
            FR_s2 = [FR_s2; fuCount];
            NonFcspRate_s2 = [NonFcspRate_s2; fuKeptCount];
            FcspRate_s2 = [FcspRate_s2; fcspCount];
        end
    end
end
end

function [fuCount, fuKeptCount] = processSingleTrial(fuRaster, luRaster, BaselineLength, SampleOdorLength, BinID)
% Process a single trial: identify and count non-FCSP spikes
% Extract FU spikes within the target time window
tempRG_FU = horzcat(fuRaster{:});
tempRG_FU = tempRG_FU(tempRG_FU > BaselineLength + SampleOdorLength + BinID - 1 & ...
    tempRG_FU <= BaselineLength + SampleOdorLength + BinID);

% Extract LU spikes within the target time window
tempRG_LU = horzcat(luRaster{:});
tempRG_LU = tempRG_LU(tempRG_LU >= BaselineLength + SampleOdorLength + BinID - 1 & ...
    tempRG_LU < BaselineLength + SampleOdorLength + BinID);

% Identify spikes not preceded by leading unit activity (i.e., not FCSP-related)
KeptSpkId = [];
for iSpk = 1:numel(tempRG_FU)
    isFCSP = any(tempRG_FU(iSpk) - tempRG_LU <= 0.01 & tempRG_FU(iSpk) - tempRG_LU > 0.002);
    if ~isFCSP
        KeptSpkId = [KeptSpkId; iSpk];
    end
end

fuCount = numel(tempRG_FU);
fuKeptCount = numel(tempRG_FU(KeptSpkId));
end

function setupParallelPool(numWorkers)
% Initialize parallel pool if not already running
poolobj = gcp('nocreate');
if isempty(poolobj)
    myCluster = parcluster('local');
    myCluster.NumWorkers = numWorkers;
    parpool(myCluster, numWorkers);
end
end