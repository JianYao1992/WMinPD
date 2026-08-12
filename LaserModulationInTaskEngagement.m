%% Trajectory in laser-off and laser-on conditions

clear; clc; close all;

%% Assignment
TarReg = {'mPFC','aAIC'};
phase = 'Learning';
% high-quality neurons criteria
FRcriteria = 1;
ISIcriteria = 0.0025;
% event duration
BaselineLength = 8;
SampleOdorLength = 1;
DelayLength = 6;
TestOdorLength = 1;
ResponseWindowLength = 1;
TimeGain = 10;
ShuffleTimes = 1000;
% target directory
Path = 'G:\LaserActivationOnOffinODPA\Training';

%% Load information of neurons in the target brain region
fprintf('Loading units information\n');
load(fullfile(Path,'UnitsInformation_LaserOnOff.mat'),'UnitsInformation');
UnitsID = 1:size(UnitsInformation,1);
% load(fullfile(DataPath,'SortedMemUnitsID_LaserOnOff.mat'),'SortedMemUnitsID');

%% Judge activated, inhibted, or unmodulated unit by laser application
ModulatedUnitsIDbyLaser = struct('mPFC', struct('Activated',[],'Inhibited',[],'Unmodulated',[]),...
    'aAIC', struct('Activated',[],'Inhibited',[],'Unmodulated',[]));
for iReg = 1:numel(TarReg)
    tempReg = TarReg{iReg};
    fprintf('Processing %s neurons\n',tempReg);
    IsTarReg = cellfun(@(x) contains(x,tempReg),UnitsInformation(:,3),'UniformOutput',true);
    IsAboveFRcriteria = cellfun(@(x) x>=FRcriteria,UnitsInformation(:,7),'UniformOutput',true);
    IsAboveISIcriteria = cellfun(@(x) x<=ISIcriteria,UnitsInformation(:,8),'UniformOutput',true);
    TarUnitsInfo = UnitsInformation(IsTarReg&IsAboveFRcriteria&IsAboveISIcriteria,:);
    TarUnitsID = UnitsID(IsTarReg&IsAboveFRcriteria&IsAboveISIcriteria);
    for iUnit = 1:size(TarUnitsInfo,1)
        % laser off
        tempFR_laseroff = TarUnitsInfo{iUnit,12}.laseroff;
        tempFR_laseroff = vertcat(tempFR_laseroff{:});
        tempAverDelayFR_laseroff = mean(tempFR_laseroff(:,(BaselineLength+SampleOdorLength)*TimeGain+2:(BaselineLength+SampleOdorLength+DelayLength)*TimeGain+1),2);
        % laser on
        tempFR_laseron = TarUnitsInfo{iUnit,12}.laseron;
        tempFR_laseron = vertcat(tempFR_laseron{:});
        tempAverDelayFR_laseron = mean(tempFR_laseron(:,(BaselineLength+SampleOdorLength)*TimeGain+2:(BaselineLength+SampleOdorLength+DelayLength)*TimeGain+1),2);
        pvalue = ranksum(tempAverDelayFR_laseroff,tempAverDelayFR_laseron);
        if pvalue > 0.05
            ModulatedUnitsIDbyLaser.(tempReg).Unmodulated = [ModulatedUnitsIDbyLaser.(tempReg).Unmodulated; ...
                {horzcat(TarUnitsID(iUnit),mean(tempAverDelayFR_laseroff),mean(tempAverDelayFR_laseron)),...
                mean(tempFR_laseroff,1),mean(tempFR_laseron,1)}];
        else
            if mean(tempAverDelayFR_laseroff) < mean(tempAverDelayFR_laseron)
                ModulatedUnitsIDbyLaser.(tempReg).Activated = [ModulatedUnitsIDbyLaser.(tempReg).Activated; ...
                {horzcat(TarUnitsID(iUnit),mean(tempAverDelayFR_laseroff),mean(tempAverDelayFR_laseron)),...
                mean(tempFR_laseroff,1),mean(tempFR_laseron,1)}];
            elseif mean(tempAverDelayFR_laseroff) > mean(tempAverDelayFR_laseron)
                ModulatedUnitsIDbyLaser.(tempReg).Inhibited = [ModulatedUnitsIDbyLaser.(tempReg).Inhibited; ...
                {horzcat(TarUnitsID(iUnit),mean(tempAverDelayFR_laseroff),mean(tempAverDelayFR_laseron)),...
                mean(tempFR_laseroff,1),mean(tempFR_laseron,1)}];
            end
        end
    end

    % plot mean firing rates of activated neurons in laser-off and laser-on conditions frame-by-frame
    if size(ModulatedUnitsIDbyLaser.(tempReg).Activated,1) >= 3
        fprintf('Plotting %s activated neurons firing rates\n',tempReg);
        MeanFR_Group1 = ModulatedUnitsIDbyLaser.(tempReg).Activated(:,2);
        MeanFR_Group1 = vertcat(MeanFR_Group1{:});
        MeanFR_Group2 = ModulatedUnitsIDbyLaser.(tempReg).Activated(:,3);
        MeanFR_Group2 = vertcat(MeanFR_Group2{:});
        figure('Position',[219 303 550 400]);
        MaxFR = 1.5*max(horzcat(mean(MeanFR_Group1,1),mean(MeanFR_Group2,1)));
        plotshadow(MeanFR_Group1, [0 0 0], 2, 3, -1*(BaselineLength+0.15), TimeGain);
        plotshadow(MeanFR_Group2, [1 0 0], 2, 3, -1*(BaselineLength+0.15), TimeGain);
        PlotEventCurve(0, SampleOdorLength, DelayLength, TestOdorLength, ResponseWindowLength, 1, MaxFR);
        % cluster-based permutation test
        [SigTime,SigLessThanChanceTime] = ClusterBasedPermutationTest('Between recordings', MeanFR_Group1, MeanFR_Group2,...
            size(MeanFR_Group1,2), ShuffleTimes, 2);
        % label significant time bins
        LabelSignificantPositions(horzcat(SigTime,SigLessThanChanceTime)-(BaselineLength+0.15)*TimeGain,TimeGain,MaxFR-1,[0 0 0]);
        SetXYaxisProperty(-1*BaselineLength,1,SampleOdorLength+DelayLength+TestOdorLength+ResponseWindowLength+BaselineLength,-0.5,SampleOdorLength+DelayLength+TestOdorLength+ResponseWindowLength,'Time from sample onset (s)',0,ceil(round(MaxFR)/6),6*ceil(round(MaxFR)/6),0,MaxFR,'Firing rate (Hz)',12,12);
        box off;
        % save figure
        title(sprintf('NUMgroup1 = %d, NUMgroup2 = %d',size(MeanFR_Group1,1),size(MeanFR_Group2,1)));
        set(gcf,'Renderer','Painter'); saveas(gcf,fullfile(Path,sprintf('Compare %s activated neurons averaged firing rates frame by frame_Between laseroff and laseron_%s',tempReg,phase)),'fig');
        close all;
    end

    % plot mean firing rates of inhibited neurons in laser-off and laser-on conditions frame-by-frame
    if size(ModulatedUnitsIDbyLaser.(tempReg).Inhibited,1) >= 3
        fprintf('Plotting %s inhibited neurons firing rates\n',tempReg);
        MeanFR_Group1 = ModulatedUnitsIDbyLaser.(tempReg).Inhibited(:,2);
        MeanFR_Group1 = vertcat(MeanFR_Group1{:});
        MeanFR_Group2 = ModulatedUnitsIDbyLaser.(tempReg).Inhibited(:,3);
        MeanFR_Group2 = vertcat(MeanFR_Group2{:});
        figure('Position',[219 303 550 400]);
        MaxFR = 1.5*max(horzcat(mean(MeanFR_Group1,1),mean(MeanFR_Group2,1)));
        plotshadow(MeanFR_Group1, [0 0 0], 2, 3, -1*(BaselineLength+0.15), TimeGain);
        plotshadow(MeanFR_Group2, [0 0 1], 2, 3, -1*(BaselineLength+0.15), TimeGain);
        PlotEventCurve(0, SampleOdorLength, DelayLength, TestOdorLength, ResponseWindowLength, 1, MaxFR);
        % cluster-based permutation test
        [SigTime,SigLessThanChanceTime] = ClusterBasedPermutationTest('Between recordings', MeanFR_Group1, MeanFR_Group2,...
            size(MeanFR_Group1,2), ShuffleTimes, 2);
        % label significant time bins
        LabelSignificantPositions(horzcat(SigTime,SigLessThanChanceTime)-(BaselineLength+0.15)*TimeGain,TimeGain,MaxFR-1,[0 0 0]);
        SetXYaxisProperty(-1*BaselineLength,1,SampleOdorLength+DelayLength+TestOdorLength+ResponseWindowLength+BaselineLength,-0.5,SampleOdorLength+DelayLength+TestOdorLength+ResponseWindowLength,'Time from sample onset (s)',0,ceil(round(MaxFR)/6),6*ceil(round(MaxFR)/6),0,MaxFR,'Firing rate (Hz)',12,12);
        box off;
        % save figure
        title(sprintf('NUMgroup1 = %d, NUMgroup2 = %d',size(MeanFR_Group1,1),size(MeanFR_Group2,1)));
        set(gcf,'Renderer','Painter'); saveas(gcf,fullfile(Path,sprintf('Compare %s inhibited neurons averaged firing rates frame by frame_Between laseroff and laseron_%s',tempReg,phase)),'fig');
        close all;
    end

    % Scatter plot
    fprintf('Plotting all %s neurons firing rates\n',tempReg);
	figure('position',[300 200 500 500]);
    % Activated unit
    if ~isempty(ModulatedUnitsIDbyLaser.(tempReg).Activated)
    	for iUnit = 1:size(ModulatedUnitsIDbyLaser.(tempReg).Activated,1)
            plot(ModulatedUnitsIDbyLaser.(tempReg).Activated{iUnit,1}(2),...
                ModulatedUnitsIDbyLaser.(tempReg).Activated{iUnit,1}(3),...
                'Marker','o','MarkerSize',2,'MarkerFaceColor',[1 0 0],'MarkerEdgeColor','none');
            hold on;
        end
    end
    % Inhibited unit
    if ~isempty(ModulatedUnitsIDbyLaser.(tempReg).Inhibited)
    	for iUnit = 1:size(ModulatedUnitsIDbyLaser.(tempReg).Inhibited,1)
            plot(ModulatedUnitsIDbyLaser.(tempReg).Inhibited{iUnit,1}(2),...
                ModulatedUnitsIDbyLaser.(tempReg).Inhibited{iUnit,1}(3),...
                'Marker','o','MarkerSize',2,'MarkerFaceColor',[0 0 1],'MarkerEdgeColor','none');
            hold on;
        end
    end
    % Unmodulated unit
    if ~isempty(ModulatedUnitsIDbyLaser.(tempReg).Unmodulated)
    	for iUnit = 1:size(ModulatedUnitsIDbyLaser.(tempReg).Unmodulated,1)
            plot(ModulatedUnitsIDbyLaser.(tempReg).Unmodulated{iUnit,1}(2),...
                ModulatedUnitsIDbyLaser.(tempReg).Unmodulated{iUnit,1}(3),...
                'Marker','o','MarkerSize',2,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor','none');
            hold on;
        end
    end
	plot([0 50],[0 50],'k--'); hold on
	SetXYaxisProperty(0,10,50,0,50,'Laser-off firing rate (Hz)',0,10,50,0,50,'Laser-on firing rate (Hz)',12,12);
	set(gcf,'Render','Painter'); saveas(gcf,fullfile(Path,sprintf('All %s UnitsDelayFR_LaserOnOff_%s',TarReg{iReg},phase)),'fig'); close;
end
save(fullfile(Path,sprintf('Laser modulations of delay-period activity in task engagement_%s.mat',phase)),'ModulatedUnitsIDbyLaser','-v7.3');
