%% Calculate Persistence of Cross-Temporal Decoding Results (Delay Period)

clear; clc; close all;
addpath(genpath('/home/yaojian/Codes/Function'));

%% Configuration Parameters
config = struct();
config.IsBetwDiffMice = 1;          % Compare across mice groups (1) or laser conditions (0)
config.TarUnits = 'mPFC-Memory units';
config.UnitsNum = 80;
config.TimeGain = 10;
config.BaseLen = 0.5;               
config.SampOdorLen = 1;             

% Group-specific configuration
if config.IsBetwDiffMice
    config.homedir = '/home/yaojian/NoLaserinODPA';
    config.Group = {'Healthy','PDmodel'};
    config.DelayLen = 10;
    config.colorset = {[0 0 0], [0 125 0]/255};
    config.figNamePrefix = 'Compare persistence';
else
    config.homedir = '/home/yaojian/LaserActivationOnOffinODPA/Training';
    config.Group = {'laseroff','laseron'};
    config.DelayLen = 6;
    config.colorset = {[0 125 0]/255, [67 106 178]/255};
    config.figNamePrefix = 'Compare persistence in SNCA';
end

%% Load Persistence Data
persistenceData = cell(1, length(config.Group));
for i = 1:length(config.Group)
    % Set file path
    if config.IsBetwDiffMice
        filePath = fullfile(config.homedir, config.Group{i}, 'Training');
    else
        filePath = config.homedir;
    end
    
    % Load and normalize data
    fileName = sprintf('ClusterBasedPermuTestIsSigBetterAndLowerthanShuffle-n=%d-%s-%s', ...
        config.UnitsNum, config.TarUnits, config.Group{i});
    data = load(fullfile(filePath, fileName), 'Persistence');
    persistenceData{i} = data.Persistence / config.TimeGain;
end

%% Visualization and Statistical Test
% Create figure
fig = figure('OuterPosition', [219 303 420 534], 'Renderer', 'Painter');
xPosOffset = 0.8;
xPosBase = 1.1;

% Plot bars, error bars, and scatter points
hold on;
for i = 1:length(config.Group)
    xPos = xPosBase + xPosOffset*(i-1);
    % Plot bar with error
    plotBarAndError(config.colorset{i}, xPos, persistenceData{i}, 1);
    % Plot individual data points (jittered for visibility)
    jitter = randn(size(persistenceData{i})) * 0.08;
    scatter(xPos + jitter, persistenceData{i}, 1, config.colorset{i}, 'filled');
end
hold off;

% Configure axes
xLim = [0.6, xPosBase + xPosOffset*(length(config.Group)-1) + 0.5];
yLim = [0, config.DelayLen];
SetXYaxisProperty([], [], [], xLim(1), xLim(2), 'Group', ...
    yLim(1), 1, yLim(2), yLim(1), yLim(2), 'Persistence (s)', 12, 12);
box off;

% Statistical test (ranksum)
[pVal, ~] = ranksum(persistenceData{1}, persistenceData{2});
title(sprintf('Ranksum test, p=%.4f', pVal));

% Save figure
figName = sprintf('%s-n=%d-%s-between %s and %s', ...
    config.figNamePrefix, config.UnitsNum, config.TarUnits, ...
    config.Group{1}, config.Group{2});
saveas(fig, fullfile(config.homedir, figName), 'fig');

% Cleanup
close(fig);