%% Compare FC density changes between circuits

clear; clc; close all;

addpath(genpath('/home/yaojian/Codes/Function'));

pairType = 'ConAct';

baseDir = '/home/yaojian/NoLaserinODPA';
dataDirs.Healthy = fullfile(baseDir, 'Healthy', 'Training');
dataDirs.PDmodel = fullfile(baseDir, 'PDmodel', 'Training');

circuits = struct( ...
    'name',  {'mPFC-aAIC', 'aAIC-aAIC', 'mPFC-mPFC'}, ...
    'label', {'P2I',       'I2I',       'P2P'} ...
);

colorvalue = [0 125 0]/255;

densityField = getField(pairType);
fcDensity = struct();

%% Load FC density data
for iCircuit = 1:numel(circuits)
    circuitName = circuits(iCircuit).name;
    circuitLabel = circuits(iCircuit).label;

    fcDensity.(circuitLabel).Healthy = loadFcDensity(dataDirs.Healthy, circuitName, densityField);
    fcDensity.(circuitLabel).PDmodel = loadFcDensity(dataDirs.PDmodel, circuitName, densityField);
end

%% Cochran's Q test
[g_P2I, g_I2I, g_P2P, p_value, I2] = CochranQtest( ...
    fcDensity.P2I.PDmodel, fcDensity.P2I.Healthy, ...
    fcDensity.I2I.PDmodel, fcDensity.I2I.Healthy, ...
    fcDensity.P2P.PDmodel, fcDensity.P2P.Healthy);

%% Plot and save results
effectSizes = [g_P2I, g_I2I, g_P2P];
figure('OuterPosition', [219 303 420 534],'Renderer','Painters');
plot(effectSizes, '-', ...
    'Color', colorvalue, ...
    'Marker', 'o', ...
    'MarkerFaceColor', colorvalue, ...
    'MarkerEdgeColor', 'none');

SetXYaxisProperty( ...
    0, 1, 10, 0.5, numel(circuits) + 0.5, ...
    [], -10, 1, 0, -5, 0, ...
    'Hedges'' g', 12, 12);

figurePath = fullfile(baseDir, sprintf('FC density change effect size between circuits_%s', pairType));
resultPath = fullfile(baseDir, sprintf('FC density change effect size between circuits_%s.mat', pairType));

saveas(gcf, figurePath,'fig');
save(resultPath, 'g_P2I', 'g_I2I', 'g_P2P', 'p_value', 'I2', '-v7.3');
close all;

%% Local functions
function densityField = getField(pairType)
    pairFields = struct( ...
        'ConAct',     'Density_ConAct', ...
        'ConInact',   'Density_ConInact', ...
        'InconAct',   'Density_InconAct', ...
        'InconInact', 'Density_InconInact', ...
        'Nonmemory',  'Density_nonmemory' ...
    );

    if ~isfield(pairFields, pairType)
        error('Unsupported pair type: %s', pairType);
    end

    densityField = pairFields.(pairType);
end

function density = loadFcDensity(Directory, Circuit, Field)
    filePattern = sprintf('*SessionBased FC density*%s*.mat', Circuit);
    matchedFiles = dir(fullfile(Directory, filePattern));

    if isempty(matchedFiles)
        error('No FC density file found for circuit "%s" in "%s".', Circuit, Directory);
    end

    if numel(matchedFiles) > 1
        error('Multiple FC density files found for circuit "%s" in "%s".', Circuit, Directory);
    end

    loadedData = load(fullfile(Directory, matchedFiles.name));

    if ~isfield(loadedData, 'FCdensity') || ~isfield(loadedData.FCdensity, Field)
        error('Field "FCdensity.%s" is missing in "%s".', Field, matchedFiles.name);
    end

    density = loadedData.FCdensity.(Field);
end
