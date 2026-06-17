%% Merge and process shuffled data

clear; clc; close all;

%% Configuration Parameters
params = struct();
params.IsLaserOnOffDesign = 0;       % 0 = No laser, 1 = Laser on/off design
params.Group = 'PDmodel';            % Experimental group name
params.LaserType = 'laseron';
params.TargetUnits = 'mPFC-Memory units'; % Target neurons
params.UnitsNumber = 80;             % Number of units analyzed

%% Define File Paths
if params.IsLaserOnOffDesign == 0
    basePath = '/home/yaojian/NoLaserinODPA';
    savePath = fullfile(basePath, params.Group, 'Training');
    filePattern = sprintf('*Shuffle-%s-n=%d-NullDistributionID*%s*.mat', ...
    params.TargetUnits, params.UnitsNumber, params.Group);
else
    savePath = '/home/yaojian/LaserActivationOnOffinODPA/Training';
    filePattern = sprintf('*Shuffle-%s-n=%d-NullDistributionID*%s*.mat', ...
    params.TargetUnits, params.UnitsNumber, params.LaserType);
end
dataFiles = dir(fullfile(savePath, filePattern));

% Validate file existence
if isempty(dataFiles)
    error('No shuffled data files found in path: %s', savePath);
end

%% Process and Aggregate Data
numFiles = length(dataFiles);
aggregatedData = [];

for fileIdx = 1:numFiles
    % Progress feedback
    fprintf('Processing %d of %d files: %s\n', fileIdx, numFiles, dataFiles(fileIdx).name);
    
    % Load file and extract relevant data
    fileData = load(fullfile(savePath, dataFiles(fileIdx).name));
    lossResults = fileData.DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;
    
    % Calculate mean (squeeze removes singleton dimensions) and aggregate
    meanResults = squeeze(mean(lossResults, 2));
    aggregatedData = [aggregatedData; meanResults];
end

%% Save Aggregated Results
if params.IsLaserOnOffDesign == 0
    outputFileName = sprintf('%s-n=%d-ShuffledTCT-%s.mat', ...
        params.TargetUnits, params.UnitsNumber, params.Group);
else
    outputFileName = sprintf('%s-n=%d-ShuffledTCT-%s.mat', ...
        params.TargetUnits, params.UnitsNumber, params.LaserType);
end
save(fullfile(savePath, outputFileName), 'aggregatedData', '-v7.3');
fprintf('Successfully saved aggregated results to: %s\n', fullfile(savePath, outputFileName));

%% Clean Up Individual Shuffled Files
fprintf('Cleaning up individual shuffled data files...\n');
for fileIdx = 1:numFiles
    filePath = fullfile(savePath, dataFiles(fileIdx).name);
    delete(filePath);
    fprintf('Deleted: %s\n', filePath);
end

fprintf('\nAll operations completed successfully!\n');
