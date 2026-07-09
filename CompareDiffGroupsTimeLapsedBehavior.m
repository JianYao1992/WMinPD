function CompareDiffGroupsTimeLapsedBehavior(phase, parameter, delaytype, data, ...
    color_line, width_line, style_line, shape_marker, facecolor_marker, edgecolor_marker, size_marker, savepath)

% Input parameters:
%   phase: experimental phase ('Learning phase'/'Trained phase')
%   parameter: behavior indicator(e.g., 'LickRate')
%   delaytype: delay type (e.g., 'ShortDelay'/'LongDelay'）
%   IsBetwGroups: between-group comparison flag（1=Yes，0=Within-group）
%   data: cell array storing behavioral data of each group. data{iGroup}.(delaytype).(parameter) refers to data of a single group
%   color_line/width_line/style_line: plot line properties
%   shape_marker/facecolor_marker/edgecolor_marker/size_marker: plot marker properties
%   savepath: path for saving results
% Output parameter:
%   pValue: p-value derived from statistical tests (returns empty if no test is performed)

%% 1. Input parameter validation
pValue = [];
% Non-empty validation for required parameters
requiredParams = {phase, parameter, delaytype, data, savepath};
paramNames = {'phase', 'parameter', 'delaytype', 'data', 'savepath'};
for i = 1:numel(requiredParams)
    if isempty(requiredParams{i})
        error('Parameter %s cannot be empty!', paramNames{i});
    end
end
% Data format validation
if ~iscell(data)
    error('data must be a cell array!');
end
% Save path validation (create if not exist)
if ~exist(savepath, 'dir')
    mkdir(savepath);
end

%% 2. Preallocate array
numGroups = numel(data);
TargetData = cell(1, numGroups);

%% 3. Plot data curves for each group
holdState = ishold; % Save original hold state
hold on;
for groupIdx = 1:numGroups
    % Get targeted data for the current group
    groupData = data{groupIdx}.(delaytype).(parameter);
    % Plot data
    PlotCellData(groupData, color_line{groupIdx}, width_line, style_line, ...
        shape_marker, facecolor_marker{groupIdx}, edgecolor_marker{groupIdx}, size_marker, 0);
    % Store data
    TargetData{groupIdx} = groupData;
end
hold off;

%% 4. Build the base for file naming
filePrefix = fullfile(savepath, sprintf('%s comparison-%s trials-%s', ...
    parameter, delaytype, phase));

%% 5. Perform statistical tests
try % Exception handling to prevent program crash caused by single-step errors
    if numel(TargetData{1}) > 1
        % Data dimension > 1: Tw-RM-ANOVA
        pValue = GetDataMatrixForMixedRepeatedAnova(TargetData, filePrefix);
    else
        % Data dimension = 1: select test method based on the number of groups
        switch numGroups
            case 2
                % Two groups: Mann-Whitney U test
                pValue = ranksum(TargetData{1}{1}, TargetData{2}{1});
            case {3, inf} % Case of ≥3 groups: One-way ANOVA
                newTargetData = [];
                groupId = [];
                for groupIdx = 1:numGroups
                    currData = TargetData{groupIdx}{1}(:);
                    newTargetData = [newTargetData; currData];
                    groupId = [groupId; groupIdx * ones(numel(currData), 1)];
                end
                % One-way ANOVA
                [~, pValue] = anova1(newTargetData, groupId, 'off');
        end

        % Save p-value
        saveFile = fullfile(savepath, sprintf('Pvalue for %s comparison_%s_%s.mat', ...
            parameter, delaytype, phase));
        save(saveFile, 'pValue', '-v7.3');
        fprintf('p-value saved to: %s\n', saveFile);
    end
catch ME
    error('Failed to execute statistical test: %s', ME.message);
end

end