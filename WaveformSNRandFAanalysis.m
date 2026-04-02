%% Neuron property analysis
clear; clc; close all
addpath(genpath('/home/yaojian/Codes/Function'));

%% 1. Parameter configuration and path loading
IsBetwDiffMice = 0;  % 0: laser on/off group; 1: PD-model mice versus littermates
Group = 'PDmodel';
if IsBetwDiffMice == 1
    TarPath = fullfile('/home/yaojian/NoLaserinODPA', Group, 'Training');
else
    Group = 'LaserOnOff';
    TarPath = '/home/yaojian/LaserActivationOnOffinODPA/Training';
end
load(fullfile(TarPath, sprintf('UnitsInformation_%s.mat', Group)), 'UnitsInformation');

%% 2. Analysis threshold and style configuration
ColorSet = {[196 74 255]/255, [148 170 0]/255};  % color scheme for aAIC/mPFC
FRcriteria = 1;       % firing rate threshold
ISIcriteria = 0.0025; % ISI threshold
tickStep = 0.0005;    % X-axis tick step size

%% 3. Filter qualified neurons and plot FA-SNR scatter plot
fig = figure('Renderer', 'Painter');
validIdx = UnitsInformation(:,7)>=FRcriteria & UnitsInformation(:,8)<=ISIcriteria;
validUnits = UnitsInformation(validIdx, :);
for iUnit = 1:size(validUnits, 1)
    % match color scheme by brain region
    if contains(validUnits{iUnit,3},'aAIC')
        c = ColorSet{1};
    else
        c = ColorSet{2};
    end
    % plot scatter: ISI on X-axis，SNR on Y-axis
    plot(validUnits{iUnit,8}, validUnits{iUnit,9}, 'o', ...
         'MarkerFaceColor', c, 'MarkerEdgeColor', 'none', 'MarkerSize', 3);
    hold on;
end
SetXYaxisProperty(0,tickStep,ISIcriteria,-tickStep/20,ISIcriteria,'FA',0,5,40,0,40,'SNR',12,12);
box off;
set(gcf,'Renderer','Painter'); saveas(fig, fullfile(TarPath, sprintf('UnitsFAandSNR_%s.fig', Group)));
close(fig);