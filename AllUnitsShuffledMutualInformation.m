%% To calculate all units' second-based mutual information.

clear; clc; close all;
tic

%% Assignment
Group = {'Healthy','PDmodel'};
TimeGain = 10;
WorkerNumber = 20;
ShuffledTimes = 100;

%% Parallel pool
fprintf('Getting parallel pool\n');
poolobj = gcp('nocreate'); % If no pool, do not create new one
if isempty(poolobj)
    myCluster = parcluster('local'); myCluster.NumWorkers = WorkerNumber; parpool(myCluster,WorkerNumber);
end

%% Second-based shuffled mutual information
for iGroup = 1:numel(Group)
    tempGroup = Group{iGroup};
    fprintf('Calculating shuffled mutual information of all units in %s group\n',tempGroup);
    homedir = fullfile('G:\NoLaserinODPA',tempGroup,'Training');

    %% Load "UnitsInformation" file
    load(fullfile(homedir,strcat('UnitsInformation_',tempGroup,'.mat')));
    AllUnitsShuffledMI = cell(size(UnitsInformation,1),1);

    %% Second-based mutual information
    for iUnit = 1:size(UnitsInformation,1)
        fprintf('Calculating %dth unit of total %d units\n',iUnit,size(UnitsInformation,1));
        tempFR_S1 = UnitsInformation{iUnit,17}; % individual neuron's FR of S1 trials
        tempFR_S2 = UnitsInformation{iUnit,18}; % individual neuron's FR of S2 trials
        ShuffledMI = zeros(ShuffledTimes,floor(size(tempFR_S1,2)/TimeGain));
        for iShuffle = 1:ShuffledTimes
            f(iShuffle) = parfeval(@ShuffledMutualInformationCalculation,1,...
                vertcat(tempFR_S1,tempFR_S2),size(tempFR_S1,1),TimeGain);
        end
        for iShuffle = 1:ShuffledTimes
            [~,tempShuffledMI] = fetchNext(f);
            ShuffledMI(iShuffle,:) = tempShuffledMI;
        end
        AllUnitsShuffledMI{iUnit} = mean(ShuffledMI,1);
    end
    fprintf('Saving shuffled mutual information of all units in %s group\n',tempGroup);
    save(fullfile(homedir,strcat('UnitsShuffledMutualInformation_',tempGroup,'.mat')),'AllUnitsShuffledMI','-v7.3');
end
toc



