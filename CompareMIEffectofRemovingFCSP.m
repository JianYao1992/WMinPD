%% Compare effect of removing FCSP events on STM-encoding ability (MI) of following neurons.
%   mode = 'No laser'        -> compare healthy vs PD model
%   mode = 'Laser on off'  -> compare laser-off vs laser-on

clear; clc; close all;

%% Mode selection
mode = 'No laser';   % 'No laser' or 'Laser on off'

%% Shared parameters
Reg              = {'mPFC-aAIC','aAIC-aAIC','mPFC-mPFC','aAIC-mPFC'};
binsize          = '2msbin';
latency          = '10ms';
tag              = sprintf('%s-%s', binsize, latency);
IsFRcontrolled   = 0;
FRrange      = [0 10000];
resampEdges  = [0 20 60 120 400 inf];
resampValues = [0.8 0.7 0.5 0.3 0.07];

% Mapping from friendly region name to struct field in the loaded 'eit' variable
regField = struct( ...
    'mPFCaAIC','mPFCaAIC', ...
    'aAICaAIC','aAICaAIC', ...
    'mPFCmPFC','mPFCmPFC', ...
    'aAICmPFC','aAICmPFC');

% Bootstrap sampling ratio
switch mode
    case 'No laser'
        color        = {[0 0 0], [0 125 0]/255};
        savepath     = '/home/yaojian/NoLaserinODPA';
        bs = {'Healthy','PDmodel'};
        GroupCount = 2;
    case 'Laser on off'
        color        = {[0 125 0]/255, [67 106 178]/255};
        savepath     = '/home/yaojian/LaserActivationOnOffinODPA/Training';
        bs = {'laseroff','laseron'};
        GroupCount = 2;
    otherwise
        error('Unknown mode "%s". Use "No laser" or "Laser on off".', mode);
end

%% Preallocate outputs
nReg = numel(Reg);
bsvalue_memtomem     = cell(1, nReg);
bsvalue_nonmemtomem  = cell(1, nReg);

p_MemLU_betwgroups      = ones(1, nReg);
p_NonmemLU_betwgroups   = ones(1, nReg);
if GroupCount == 3
    p_MemLU_withingroup    = ones(1, nReg);
    p_NonmemLU_withingroup = ones(1, nReg);
end

%% Load EIT results
[eit, eitGroups] = LoadEitResult(mode, savepath, tag);

%% Main loop over regions
figure('position', [200 200 300 500]);
for iReg = 1:nReg
    fld = regField.(strrep(Reg{iReg}, '-', ''));

    [val_memtomem,    val_nonmemtomem]    = extractChangedValues(eit, eitGroups, fld);
    val_memtomem     = maybeFilterFR(val_memtomem,     IsFRcontrolled, FRrange);
    val_nonmemtomem  = maybeFilterFR(val_nonmemtomem,  IsFRcontrolled, FRrange);

    %% Memory-to-memory bars
    bsvalue_memtomem{iReg} = bootstrapGrouped(val_memtomem, resampEdges, resampValues);
    [pMem, pMemWithin] = compareGroups(bsvalue_memtomem{iReg}, GroupCount);
    p_MemLU_betwgroups(iReg) = pMem;
    if GroupCount == 3
        p_MemLU_withingroup(iReg) = pMemWithin;
    end
    plotMedianAndConfidenceInterval(color{1}, 1.1 + 3.6*(iReg-1), bsvalue_memtomem{iReg}{1}, 0.3);
    plotMedianAndConfidenceInterval(color{2}, 1.9 + 3.6*(iReg-1), bsvalue_memtomem{iReg}{2}, 0.3);

    %% Non-memory-to-memory bars
    bsvalue_nonmemtomem{iReg} = bootstrapGrouped(val_nonmemtomem, resampEdges, resampValues);
    [pNonmem, pNonmemWithin] = compareGroups(bsvalue_nonmemtomem{iReg}, GroupCount);
    p_NonmemLU_betwgroups(iReg) = pNonmem;
    if GroupCount == 3
        p_NonmemLU_withingroup(iReg) = pNonmemWithin;
    end
    plotMedianAndConfidenceInterval(color{1}, 2.7 + 3.6*(iReg-1), bsvalue_nonmemtomem{iReg}{1}, 0.3);
    plotMedianAndConfidenceInterval(color{2}, 3.5 + 3.6*(iReg-1), bsvalue_nonmemtomem{iReg}{2}, 0.3);
end

%% Axis styling, save figure and p-values
SetXYaxisProperty(1.1, 0.8, 100, 0.6, 4 + 3.6*(nReg-1), ...
            'Removing FCSPs from one LU', -1, 0.1, 1, -0.1, 0.5, 'EIT of FCSPs', 12, 12);
switch mode
    case 'No laser'
        p_betreg12 = bstest(bsvalue_memtomem{1}{1}, bsvalue_memtomem{2}{1});
        p_betreg13 = bstest(bsvalue_memtomem{1}{1}, bsvalue_memtomem{3}{1});
        set(gcf, 'Renderer', 'Painter');
        saveas(gcf, fullfile(savepath, sprintf('Compare EIT-%s-between SNCA and littermates', tag)), 'fig');
        close;
        save(fullfile(savepath, 'p value for EIT comparison between SNCA and littermates.mat'), ...
            'p_MemLU_betwgroups', 'p_MemLU_withingroup', ...
            'p_NonmemLU_betwgroups', 'p_NonmemLU_withingroup', ...
            'p_betreg12', 'p_betreg13', '-v7.3');
    case 'Laser on off'
        box off;
        set(gcf, 'Renderer', 'Painter');
        saveas(gcf, fullfile(savepath, sprintf('Compare EIT-%s-between laser off and on', tag)), 'fig');
        close all;
        save(fullfile(savepath, 'p value for EIT comparison between laser off and on.mat'), ...
            'p_MemLU_betwgroups', 'p_NonmemLU_betwgroups', '-v7.3');
end

%% ----------------- Helper functions ----------------- %%
function [eit, groupNames] = LoadEitResult(mode, path, tag)
    switch mode
        case 'No laser'
            eit = cell(1, 3);
            for k = 1:2
                switch k
                    case 1  % control
                        f = fullfile(path, 'Healthy', 'Training', ...
                            sprintf('Decreased FU MI with removing FCSP-%s-Healthy.mat', tag));
                    case 2  % PD model
                        f = fullfile(path, 'PDmodel', 'Training', ...
                            sprintf('Decreased FU MI with removing FCSP-%s-PDmodel.mat', tag));
                end
                tmp = load(f);
                eit{k} = tmp.eit;
            end
            groupNames = {'Healthy','PDmodel'};
        case 'Laser on off'
            s = load(fullfile(path, sprintf('Decreased FU MI with removing FCSP-%s-LaserOnOff.mat', tag)));
            eit = s.eit;
            groupNames = {'laseroff','laseron'};
    end
end

function [memVals, nonmemVals] = extractChangedValues(eit, groupNames, Region, mode)
n = numel(groupNames);
memVals    = cell(1, n);
nonmemVals = cell(1, n);
for k = 1:n
    if strcmp(mode,'No laser')
        root = eit{k}.(Region);
        memVals{k}    = -1 * root.ChangedValue_memtomem{1,1};
        nonmemVals{k} = -1 * root.ChangedValue_nonmemtomem{1,1};
    elseif strcmp(mode,'Laser on off')
        root = eit.(Region);
        if k == 1
            memVals{k} = -1 * root.ChangedValue_memtomem.laseroff{1,1};
            nonmemVals{k} = -1 * root.ChangedValue_nonmemtomem.laseroff{1,1};
        elseif k == 2
            memVals{k} = -1 * root.ChangedValue_memtomem.laseron{1,1};
            nonmemVals{k} = -1 * root.ChangedValue_nonmemtomem.laseron{1,1};
        end
    end
end
end

function values = maybeFilterFR(values, isFilterFR, FRrange)
    if isFilterFR ~= 1, return; end
    for k = 1:numel(values)
        v = values{k};
        if ~isempty(v)
            values{k} = v(v(:,6) >= FRrange(1) & v(:,6) <= FRrange(2), :);
        end
    end
end

function bsValues = bootstrapGrouped(Values, Edges, Ratios)
    nGroups = numel(Values);
    bsValues = cell(1, nGroups);
    sizes = cellfun(@(v) size(v,1), Values);
    nMin = min(sizes);
    bsratio = Ratios(find(nMin >= Edges, 1, 'last'));
    for k = 1:nGroups
        bsValues{k} = BootstrapCalculation(Values{k}(:,1), 1000, floor(bsratio*size(Values{k},1)));
    end
end

function [pBetween, pWithin] = compareGroups(bsValues, GroupNumber)
    pBetween = bstest(bsValues{1}, bsValues{2});
    if GroupNumber >= 3
        pWithin = bstest(bsValues{1}, bsValues{3});
    else
        pWithin = [];
    end
end

