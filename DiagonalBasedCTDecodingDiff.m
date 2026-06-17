%% Compare CTD Decoding Accuracy

clear; clc; close all;
addpath(genpath('/home/yaojian/Codes/Function'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USER CONFIGURATION - SELECT ANALYSIS MODE HERE
% Set to 'No laser' for Healthy/PDmodel comparison 
% Set to 'Laser on off' for laser on/off comparison
analysis_mode = 'No laser';
Classifier = 'MCC';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Core Parameters
TimeGain = 10;
UnitsNum = 80;
TarUnits = 'mPFC-Memory units';
BaseLen = 2;
SampOdorLen = 1;
switch analysis_mode
    case 'No laser'
        homedir = '/home/yaojian/NoLaserinODPA';
        Group = {'Healthy','PDmodel'};
        ColorSets = {[0 0 0],[0 125 0]/125};
        DelayLen = 10;
        save_filename = sprintf('Decoding accuracy aligning to diagonal between SNCA and littermates-%d %s',UnitsNum,TarUnits);

    case 'Laser on off'
        homedir = '/home/yaojian/LaserActivationOnOffinODPA/Training';
        Group = {'laseroff','laseron'};
        ColorSets = {[0 125 0]/255, [67 106 178]/255};
        DelayLen = 6;
        save_filename = sprintf('Decoding accuracy aligning to diagonal between laser on and off in SNCA-%d %s',UnitsNum,TarUnits);

    otherwise
        error('Invalid analysis mode! Choose "No laser" or "Laser on off"');
end

% Delay-period time bin
delay_bin_min = (BaseLen+SampOdorLen)*TimeGain + 1;
delay_bin_max = (BaseLen+SampOdorLen+DelayLen)*TimeGain;

%% Load CTD Results
switch analysis_mode
    case 'No laser'
        load(fullfile(homedir,Group{1},'Training',sprintf('%s-n=%d-%s-NullDistributionID-1-All Parameters-%s.mat',TarUnits,UnitsNum,Group{1},Classifier)));
        CTDecoding_1 = squeeze(mean(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results,2));
        
        load(fullfile(homedir,Group{2},'Training',sprintf('%s-n=%d-%s-NullDistributionID-1-All Parameters-%s.mat',TarUnits,UnitsNum,Group{2},Classifier)));
        CTDecoding_2 = squeeze(mean(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results,2));

    case 'Laser on off'
        load(fullfile(homedir,sprintf('%s-n=%d-%s-NullDistributionID-1-All Parameters-%s.mat',TarUnits,UnitsNum,Group{1},Classifier)));
        CTDecoding_1 = squeeze(mean(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results,2));
        
        load(fullfile(homedir,sprintf('%s-n=%d-%s-NullDistributionID-1-All Parameters-%s.mat',TarUnits,UnitsNum,Group{2},Classifier)));
        CTDecoding_2 = squeeze(mean(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results,2));
end

%% Time Bin Filtering
X = 1:size(CTDecoding_1,2); 
TimeLampDelayBinID = find(X >= delay_bin_min & X <= delay_bin_max);
DecodingResult_1 = CTDecoding_1(:,TimeLampDelayBinID,TimeLampDelayBinID);
DecodingResult_2 = CTDecoding_2(:,TimeLampDelayBinID,TimeLampDelayBinID);

%% Calculate Decoding Accuracy by Time Separation from Diagonal
DelayBinNum = numel(TimeLampDelayBinID);
ReSampleTimes = size(DecodingResult_1,1);

% Initialize output matrices
Decoding_1 = zeros(ReSampleTimes,DelayBinNum);
Decoding_2 = zeros(ReSampleTimes,DelayBinNum);
DecodingDiff = zeros(ReSampleTimes,DelayBinNum);

for iResample = 1:ReSampleTimes
    % Reshape 3D data to 2D matrices
    tempDecoding_1 = reshape(DecodingResult_1(iResample,:,:),DelayBinNum,DelayBinNum);
    tempDecoding_2 = reshape(DecodingResult_2(iResample,:,:),DelayBinNum,DelayBinNum);
    tempDiff = tempDecoding_2 - tempDecoding_1;

    % Group data by time separation from diagonal
    tempDecoding_1_cell = cell(1,DelayBinNum);
    tempDecoding_2_cell = cell(1,DelayBinNum);
    tempDiff_cell = cell(1,DelayBinNum);

    for iTrainBin = 1:DelayBinNum
        for iTestBin = 1:DelayBinNum
            TimeSeparation = abs(iTestBin-iTrainBin);
            tempDecoding_1_cell{TimeSeparation+1} = [tempDecoding_1_cell{TimeSeparation+1}; tempDecoding_1(iTrainBin,iTestBin)];
            tempDecoding_2_cell{TimeSeparation+1} = [tempDecoding_2_cell{TimeSeparation+1}; tempDecoding_2(iTrainBin,iTestBin)];
            tempDiff_cell{TimeSeparation+1} = [tempDiff_cell{TimeSeparation+1}; tempDiff(iTrainBin,iTestBin)];
        end
    end

    % Calculate mean values for current resample
    AverDecoding_1 = cellfun(@mean,tempDecoding_1_cell);
    AverDecoding_2 = cellfun(@mean,tempDecoding_2_cell);
    AverDecodingDiff = cellfun(@mean,tempDiff_cell);

    % Store results (convert to percentage)
    Decoding_1(iResample,:) = 100*AverDecoding_1;
    Decoding_2(iResample,:) = 100*AverDecoding_2;
    DecodingDiff(iResample,:) = 100*AverDecodingDiff;
end

%% Plot Results
figure('OuterPosition',[219 303 420 534]);
% Plot shaded confidence intervals and mean lines
plotshadow(Decoding_1,ColorSets{1},3,5,0,TimeGain);
plotshadow(Decoding_2,ColorSets{2},3,5,0,TimeGain);

% Detect significant time bins
IsSig = PermutationTest(zeros(1,size(DecodingDiff,2)),DecodingDiff);
SigTime = find(IsSig > 0);

% Plot significant difference markers
LabelSignificantPositions(SigTime,TimeGain,85,[0 0 0]);

% Axis configuration
box off;
SetXYaxisProperty(0.1,1,(size(Decoding_1,2)+1)/TimeGain,0.1,(size(Decoding_1,2)+1)/TimeGain,...
    'Time separation from diagonal (s)',50,10,100,50,100,'Decoding accuracy (%)',12,12);

%% Save Figure
set(gcf,'Renderer', 'Painter');
saveas(gcf,fullfile(homedir,save_filename),'fig');
close all;
