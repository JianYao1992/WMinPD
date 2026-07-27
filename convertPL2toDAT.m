%% Convert .pl2 files to .dat files for Kilosort2
clear; clc; close all;

%% Add Plexon SDK to MATLAB path
if isunix
    addpath(genpath('/home/yaojian/Codes/Matlab Offline Files SDK'));
else
    addpath(genpath('D:\Codes\Matlab Offline Files SDK'));
end

%% Inputs
Group = 'Healthy';
filepath = '/home/yaojian/LaserActivationOnOffinODPA';
skipList = {'M5895_12aAIC_34mPFC_dualtasktraining(4types)_20210911_day05'};

%% List all .pl2 files recursively
if contains(filepath,'Activation')
    fl = dir(fullfile(filepath, '*', '*', '*', '*.pl2'));
else
    fl = dir(fullfile(filepath, Group, '*', '*', '*.pl2'));
end

%% Convert each .pl2 to a single .dat (channels x samples, int16)
for f = 1:numel(fl)
    rawdata = [];
    filename = fullfile(fl(f).folder, fl(f).name);
    [path, name, ~] = fileparts(filename);
    datFile  = fullfile(path, [name, '.dat']);
    if any(strcmp(name, skipList)) || exist(datFile, 'file'), continue; end
    if ~isfolder(path), mkdir(path); end

    fprintf('Reading data from %s ...\n', name);
    pl2 = PL2GetFileIndex(filename);

    % Collect SPKC channel names
    isSPKC    = cellfun(@(c) strcmp(c.SourceName, 'SPKC'), pl2.AnalogChannels);
    chanNames = cellfun(@(c) string(c.Name), pl2.AnalogChannels(isSPKC), 'UniformOutput', false);
    nCh       = numel(chanNames);

    % Stream each channel directly into the .dat file
    fid = fopen(datFile, 'w');
    for cc = 1:nCh
        fprintf('  Channel #%d/%d ... ', cc, nCh); tic
        [~, ~, ~, ~, adv] = plx_ad_v(filename, chanNames{cc});
        rawdata(:,cc) = int16(adv * 1e3);
        toc
        clear adv
    end
    fwrite(fid, rawdata, 'int16');
    fclose(fid);
    disp('Completed.');
end