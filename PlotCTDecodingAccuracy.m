%% Plot Cross-Temporal Decoding (CTD) Accuracy

clear; clc; close all;

addpath(genpath('/home/yaojian/Codes/Function'));

%% ========================= CONFIGURATION =========================
% 1: Healthy/PDModel, 2: LaserOnOff
experiment_type = 2;
Group = 'PDmodel';
TrialLaserType = 'laseroff';

% parameters
TarUnits = 'mPFC-Memory units';
NeuronCodingType = 6;       % 0: no remove; 1: remove sustained; 2: remove transient; 
                            % 3: only sustained; 4: only transient; 5: only non-memory; 6: memory
ShuffleTimesForTest = 1000; % Permutation test iterations
TimeGain = 10;              % Time bin scaling factor
UnitsNum = 80;              % Number of neurons/units
ContourColor = [1 0 0];     % Red for contours
ContourWidth = 3;        % Line width for contours
AccuracyRange = [0.35 0.85];    % Color scale range for imagesc
BaseLen = 2;
ShownBaseLen = 0.5;
SampOdorLen = 1;
TestOdorLen = 1;

% Analysis-specific parameters
switch experiment_type
    case 1 % Healthy/PDmodel Analysis
        FileSavePath = fullfile('/home/yaojian/NoLaserinODPA',Group,'Training');
        DelayLen = 10;

    case 2 % Laser On/Off Analysis
        FileSavePath = '/home/yaojian/LaserActivationOnOffinODPA/Training';
        DelayLen = 6;
end
TarPeriod = (BaseLen-ShownBaseLen)*TimeGain+1:(BaseLen+SampOdorLen+DelayLen+TestOdorLen+0.5)*TimeGain;

%% ========================= LOAD DECODING RESULTS =========================
% Get file paths based on neuron coding type
switch(NeuronCodingType)
    case 0
        rec_pattern = '*All_CTDecoding_Recording*.mat';
        shuf_pattern = '*All_CTDecoding_Shuffled*.mat';
    case 1
        rec_pattern = '*Remove sustained_CTDecoding_Recording*.mat';
        shuf_pattern = '*Remove sustained_CTDecoding_Shuffled*.mat';
    case 2
        rec_pattern = '*Remove transient_CTDecoding_Recording*.mat';
        shuf_pattern = '*Remove transient_CTDecoding_Shuffled*.mat';
    case 3
        rec_pattern = '*Only sustained_CTDecoding_Recording*.mat';
        shuf_pattern = '*Only sustained_CTDecoding_Shuffled*.mat';
    case 4
        rec_pattern = '*Only transient_CTDecoding_Recording*.mat';
        shuf_pattern = '*Only transient_CTDecoding_Shuffled*.mat';
    case 5
        rec_pattern = '*Only nonmemory_CTDecoding_Recording*.mat';
        shuf_pattern = '*Only nonmemory_CTDecoding_Shuffled*.mat';
    case 6 % Memory neurons
        if experiment_type == 1
            rec_pattern = sprintf('*%s-n=%d-%s-NullDistributionID*.mat',TarUnits,UnitsNum,Group);
            shuf_pattern = sprintf('*%s-n=%d-ShuffledTCT-%s*.mat',TarUnits,TrialLaserType,Group);
        else
            rec_pattern = sprintf('*%s-n=%d-%s-NullDistributionID*.mat',TarUnits,UnitsNum,TrialLaserType);
            shuf_pattern = sprintf('*%s-n=%d-ShuffledTCT-%s*.mat',TarUnits,TrialLaserType,TrialLaserType);
        end
end

% Load files
File_Recording = dir(fullfile(FileSavePath, rec_pattern));
File_Shuffled = dir(fullfile(FileSavePath, shuf_pattern));

% Load real decoding results
fprintf('Loading real decoding results: %s\n', File_Recording.name);
load(fullfile(FileSavePath, File_Recording.name));
RecordingDecodingResults = squeeze(mean(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results,2));

% Load shuffled decoding results
fprintf('Loading shuffled decoding results: %s\n', File_Shuffled.name);
load(fullfile(FileSavePath, File_Shuffled.name));
ShuffleDecodingResults = data;

%% ========================= PROCESS RESULTS =========================
% Average and reshape real decoding results
RecordingDecodingResults = mean(RecordingDecodingResults);
RecordingDecodingResults = reshape(RecordingDecodingResults, size(RecordingDecodingResults,2), size(RecordingDecodingResults,3));

% Cluster-based permutation test for significance
TestBinNum = size(ShuffleDecodingResults,2);
[IsSig_AboveChance,SigTime_AboveChance,Persistence,IsSig_BelowChance,SigTime_BelowChance] = ...
    ClusterBasedPermutationTest('Between real and shuffle',RecordingDecodingResults, ShuffleDecodingResults, TestBinNum, ShuffleTimesForTest, 2);

%% ========================= PLOT RESULTS =========================
fprintf('Generating CTD plot...\n');
fig = figure;
ax = axes('Parent', fig, 'Position', [0.1 0.1 0.8 0.8], 'FontSize', 14, 'FontName', 'Arial');
box(ax, 'off');
hold(ax, 'on');
colormap('jet');

% Subset results to target time range
plot_data = RecordingDecodingResults(TarPeriod,TarPeriod);
sig_data = IsSig_AboveChance(TarPeriod,TarPeriod);
sig_less_data = IsSig_BelowChance(TarPeriod,TarPeriod);

% Plot heatmap of decoding accuracy
imagesc(plot_data, AccuracyRange);

% Plot significance contours
contour(sig_data, [1 1], '-', 'Color', ContourColor, 'LineWidth', ContourWidth);
contour(sig_less_data, [1 1], '-', 'Color', ContourColor, 'LineWidth', ContourWidth);

% Plot time segment dividers
tm_base = (ShownBaseLen+0.05)*TimeGain;
tm_samp = (ShownBaseLen+SampOdorLen+0.05)*TimeGain;
tm_delay = (ShownBaseLen+SampOdorLen+DelayLen+0.05)*TimeGain;
tm_test = (ShownBaseLen+SampOdorLen+DelayLen+TestOdorLen+0.05)*TimeGain;
time_markers = [tm_base, tm_samp, tm_delay, tm_test];
arrayfun(@(t) xline(t,'k--','LineWidth',3),time_markers);
arrayfun(@(t) yline(t,'k--','LineWidth',3),time_markers);

% Set axis properties
axis_lim = (ShownBaseLen+SampOdorLen+DelayLen+TestOdorLen+0.55)*TimeGain;
SetXYaxisProperty(0.5, TimeGain, axis_lim, 0.5, axis_lim, ...
    'Test time (s)', 0.5, TimeGain, axis_lim, 0.5, axis_lim, ...
    'Train time (s)', 12, 12);

%% ========================= SAVE OUTPUTS =========================
set(fig, 'Renderer', 'Painter');
% Generate output filenames
if experiment_type == 1
    fig_name = sprintf('TCT plot-n=%d-%s-%s', UnitsNum, TarUnits, Group);
    sig_file = sprintf('ClusterBasedPermuTestIsSigBetterAndLowerthanShuffle-n=%d-%s-%s', UnitsNum, TarUnits, Group);
else
    fig_name = sprintf('TCT plot-n=%d-%s-%s', UnitsNum, TarUnits, TrialLaserType);
    sig_file = sprintf('ClusterBasedPermuTestIsSigBetterAndLowerthanShuffle-n=%d-%s-%s', UnitsNum, TarUnits, TrialLaserType);
end
% Save figure and significance data
saveas(fig, fullfile(FileSavePath, fig_name), 'fig');
save(fullfile(FileSavePath, sig_file), 'IsSig_AboveChance', 'SigTime_AboveChance','Persistence','IsSig_BelowChance','SigTime_BelowChance', '-v7.3');

% Cleanup
close(fig);
fprintf('Analysis complete. Outputs saved to: %s\n', FileSavePath);