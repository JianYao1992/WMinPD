% Output a 16-column cell matrix:1{MiceID},2{DayID},3{Region},4{UnitID},5{SpikeTime},6{Waveform},7{MeanFR},8{FalseAlarmRate},9{SNR},
% 10{TrialMarker},11{AllTrialSpikeRg},12{AllTrialFR},13{LaserTrialSpikeRg},14{LaserTrialFR},15{AllTrialLickRg},16{AllTrialLickRate}
clear; clc; close all;
tic

%% ===================== Core parameter configuration (mode + experimental parameters) =====================
Group = 'Healthy';
% Mode: 1 = basic laser processing; 2 = laser on/off (task/resting state separation)
laser_mode = 1; 
% Experimental parameters
SampOdorLen = 1;    TestOdorLen = 1;    RespWindowLen = 1;
TimeGain = 10;      SamplingRate = 40000;
if laser_mode == 1
    DelayLen = 10;  ITIlen = 15;        LaserTrialNum = 100;  
else
    DelayLen = 6;   ITIlen = 10;        LaserTrialNum = [];
end

%% ===================== Path and environment configuration =====================
addpath('/home/yaojian/Codes/Matlab Offline Files SDK');
addpath('/home/yaojian/Codes/npy-matlab-master/npy-matlab');
if laser_mode == 1
    homedir = fullfile('/home/yaojian/NoLaserinODPA',Group,'Training');
elseif laser_mode == 2
    homedir = '/home/yaojian/LaserActivationOnOffinODPA/Training';
end
FileList = dir(fullfile(homedir,'*','*','waveform.mat'));

%% ===================== Batch processing of each experimental session =====================
for iSess = 1:size(FileList,1)
    disp(['Processing data in ' FileList(iSess).folder]);
    % 1. Read PL2 files and task events
    pl2file = dir(fullfile(FileList(iSess).folder,'*.pl2*'));
    pl2path = fullfile(pl2file.folder,pl2file.name);
    OdorA = PL2EventTs(pl2path,'EVT07');  % H/Y
    OdorB = PL2EventTs(pl2path,'EVT08');  % N/B
    Lick  = PL2EventTs(pl2path,'EVT06');  % lick
    Laser = PL2EventTs(pl2path,'EVT09');  % laser

    % 2. Laser signal filtering
    if laser_mode == 1
        % basic mode: filter abnormal laser signals and retain equidistant resting-state laser signals
        NormalLaser = GetRegularLaser(Laser.Ts, min(diff(Laser.Ts)));
        LaserTime = NormalLaser;
    else
        % laser on/off mode: extract regular laser signals for task and resting states separately
        RegularLaserTs_task = GetRegularLaser(Laser.Ts, DelayLen+TestOdorLen+RespWindowLen+ITIlen+SampOdorLen);
        RegularLaserTs_rest = GetRegularLaser(Laser.Ts, DelayLen+TestOdorLen+RespWindowLen+ITIlen);
        LaserTime = {RegularLaserTs_task,RegularLaserTs_rest};
    end

    % 3. Odor timestamp validation: eliminate abnormal duplicates and signals with overly close intervals
    Ts_OdorA = OdorA.Ts;  Ts_OdorB = OdorB.Ts;
    if ~isempty(Ts_OdorA)
        Ts_OdorA(:,2) = 1;  Ts_OdorB(:,2) = 2;
        rawA = Ts_OdorA;    rawB = Ts_OdorB;
        % filter out coincident timestamps of A and B
        for itr = 1:size(rawA,1)
            if ~isempty(find(rawB(:,1)==rawA(itr,1)))
                Ts_OdorB(Ts_OdorB(:,1)==rawA(itr,1),2) = 0;
                Ts_OdorA(itr,2) = 0;
            end
            % filter out abnormal A signals where the interval is less than 0.5 seconds.
            if itr<size(rawA,1) && rawA(itr+1,1)-rawA(itr,1)<0.5
                Ts_OdorA(itr,2) = 0;
            end
        end
        % filter out abnormal B signals with intervals < 0.5 s
        for itr = 1:size(rawB,1)
            if itr<size(rawB,1) && rawB(itr+1,1)-rawB(itr,1)<0.5
                Ts_OdorB(itr,2) = 0;
            end
        end
        % remove abnormal signals labeled 0
        Ts_OdorA(Ts_OdorA(:,2)==0,:) = [];
        Ts_OdorB(Ts_OdorB(:,2)==0,:) = [];
    end

    % 4. Load basic neuronal data
    load(fullfile(FileList(iSess).folder,'waveform.mat'),'waveform');
    load(fullfile(FileList(iSess).folder,'FArateSNR.mat'),'FArateSNR');
    clusterInfo = readtable(fullfile(FileList(iSess).folder,'cluster_info.tsv'),'FileType','text','Delimiter','tab');
    spike_cluster = double(readNPY(fullfile(FileList(iSess).folder,'spike_clusters.npy')));
    spike_times = double(readNPY(fullfile(FileList(iSess).folder,'spike_times.npy')));

    % 5. Extract information and assign values for each neuron individually
    data = cell(size(waveform,1),16);
    for iUnit = 1:size(waveform,1)
        % 5.1 basic identifiers: mouse ID, session ID, brain region, unit ID
        [~, data{iUnit,1}, ~] = fileparts(fileparts(FileList(iSess).folder)); % mouse ID
        [~, temp, ~] = fileparts(FileList(iSess).folder);                     % session ID
        data{iUnit,2} = temp(end-4:end);
        % classify brain regions by channel number (1-32: left aAIC; 33-64: right aAIC; 65-96: left mPFC; 97-128: right mPFC)
        chn_max = max(waveform{iUnit,4});
        if chn_max<=32;        data{iUnit,3} = 'left aAIC';
        elseif chn_max<=64;    data{iUnit,3} = 'right aAIC';
        elseif chn_max<=96;    data{iUnit,3} = 'left mPFC';
        else;                  data{iUnit,3} = 'right mPFC';
        end
        data{iUnit,4} = waveform{iUnit,2};  % unit ID

        % 5.2 spike times and waveforms
        spikeT = spike_times(spike_cluster==data{iUnit,4})/SamplingRate;
        data{iUnit,5} = spikeT(:)';         % SpikeTime (converted to seconds)
        % waveform cropping (matches spike count to prevent index out of bounds)
        wf_size = size(waveform{iUnit,5},1);
        spike_num = numel(data{iUnit,5});
        data{iUnit,6} = waveform{iUnit,5}(1:min(spike_num-1, wf_size-1),:,:);

        % 5.3 firing rate, false alarm rate, signal-to-noise ratio
        data{iUnit,7} = table2array(clusterInfo(clusterInfo{:,1}==data{iUnit,4},8)); % mean firing rate
        data{iUnit,8} = FArateSNR(iUnit,1); % false alarm rate
        data{iUnit,9} = FArateSNR(iUnit,2); % signal-to-noise ratio

        % 5.4 temporal alignment
        [data{iUnit,10:16}] = AlignSpikesToEvents(data{iUnit,5}, Ts_OdorA, Ts_OdorB, Lick.Ts, LaserTime, LaserTrialNum,...
            SampOdorLen,DelayLen,TestOdorLen,RespWindowLen,ITIlen,TimeGain);
    end

    % 6. Save all neuronal information
    save(fullfile(FileList(iSess).folder,'IndividualSessionAllUnitsInformation.mat'),'data','-v7.3');
    % clean up temporary variables (retain core parameters)
    clearvars -except laser_mode SampOdorLen DelayLen TestOdorLen RespWindowLen ITIlen TimeGain SamplingRate LaserTrialNum FileList
end

%% Runtime information output
toc;
disp(['Total run time: ',num2str(toc),' s']);