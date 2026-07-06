%% Extract Neuron Pair Information at Population Level
%  To extract pair information including FR, AI, region, and preference data

clear; clc; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mode selection: 'No laser' or 'Laser on off'
analysismode = 'No laser'; % Change to 'Laser on off' for laser experiments
group = 'PDmodel';     % Only used for 'No laser' mode
binsize = '2msbin';        % Time bin size

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATH & TIMING PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Base path configuration
switch analysismode
    case 'No laser'
        basepath = fullfile('/home/yaojian/NoLaserinODPA', group, 'Training');
        delaylength = 10;   % Delay length for 'No laser' mode experiments
    case 'laser'
        basepath = '/home/yaojian/LaserActivationOnOffinODPA/Training';
        delaylength = 6;    % Delay length for 'Laser on off' experiments
    otherwise
        error('Invalid analysis mode! Use ''No laser'' or ''Laser on off''');
end

% Fixed timing parameters (consistent across experiments)
baselength = 1;
sampleodorlength = 1;
testodorlength = 1;
respwindowlength = 1;
totalbins = baselength + sampleodorlength + delaylength + testodorlength + respwindowlength;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN ANALYSIS LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%
for bin_id = 1:totalbins
    % Calculate time window for current bin
    bin_start = bin_id - baselength - sampleodorlength;
    bin_end = bin_start + 1;
    fprintf('////////// Processing pair information for time window [%d %d] //////////\n', bin_start, bin_end);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % LOAD STATISTICS DATA
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch analysismode
        case 'No laser'
            statsfile = fullfile(basepath, sprintf('TestFC_XCORR_stats_%d_%d_%s_%s.mat', bin_start, bin_end, binsize, group));
        case 'Laser on off'
            statsfile = fullfile(basepath, sprintf('TestFC_XCORR_stats_%d_%d_%s_LaserOnOff.mat', bin_start, bin_end, binsize));
    end

    if ~exist(statsfile, 'file')
        warning('Stats file not found: %s. Skipping this bin.', statsfile);
        continue;
    end
    load(statsfile, 'stats');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INITIALIZE DATA STRUCTURES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch analysismode
        case 'No laser'
            Pair = struct(...
                'mouse', [], 'learningday', [], 'reg', [], 'unitsid', [], ...
                'FR', struct('s1', [], 's2', []), 'preference', []);
            FCPair_s1 = struct(...
                'mouse', [], 'learningday', [], 'reg', [], 'unitsid', [], ...
                'AI', [], 'FR', [], 'preference', []);
            FCPair_s2 = struct(...
                'mouse', [], 'learningday', [], 'reg', [], 'unitsid', [], ...
                'AI', [], 'FR', [], 'preference', []);
        case 'Laser on off'
            Pair_laseroff = struct(...
                'mouse', [], 'learningday', [], 'reg', [], 'unitsid', [], ...
                'FR', struct('s1', [], 's2', []), 'preference', []);
            Pair_laseron = struct(...
                'mouse', [], 'learningday', [], 'reg', [], 'unitsid', [], ...
                'FR', struct('s1', [], 's2', []), 'preference', []);

            FCPair_s1_laseroff = struct(...
                'mouse', [], 'learningday', [], 'reg', [], 'unitsid', [], ...
                'AI', [], 'FR', [], 'preference', []);
            FCPair_s2_laseroff = struct(...
                'mouse', [], 'learningday', [], 'reg', [], 'unitsid', [], ...
                'AI', [], 'FR', [], 'preference', []);
            FCPair_s1_laseron = struct(...
                'mouse', [], 'learningday', [], 'reg', [], 'unitsid', [], ...
                'AI', [], 'FR', [], 'preference', []);
            FCPair_s2_laseron = struct(...
                'mouse', [], 'learningday', [], 'reg', [], 'unitsid', [], ...
                'AI', [], 'FR', [], 'preference', []);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PROCESS EACH NEURON PAIR
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    for pairid = 1:length(stats)
        fprintf('Analyzing pair %d/%d\n', pairid, numel(stats));

        % Get standardized region codes
        reg1 = GetRegionCode(stats{pairid}.reg_su1);
        reg2 = GetRegionCode(stats{pairid}.reg_su2);
        region_pair = horzcat(reg1, reg2);
        unitids = horzcat(stats{pairid}.su1_clusterid, stats{pairid}.su2_clusterid);
        mouseid = stats{pairid}.mouseid;
        learningday = stats{pairid}.learningdayid;

        % Process data based on analysis mode
        switch analysismode
            case 'No laser'
                % 1. All pairs
                Pair.mouse = [Pair.mouse; mouseid];
                Pair.learningday = [Pair.learningday; learningday];
                Pair.reg = [Pair.reg; region_pair];
                Pair.unitsid = [Pair.unitsid; unitids];
                Pair.FR.s1 = [Pair.FR.s1; horzcat(stats{pairid}.FRs1trials_su1(bin_id), stats{pairid}.FRs1trials_su2(bin_id))];
                Pair.FR.s2 = [Pair.FR.s2; horzcat(stats{pairid}.FRs2trials_su1(bin_id), stats{pairid}.FRs2trials_su2(bin_id))];
                Pair.preference = [Pair.preference; horzcat(stats{pairid}.prefered_sample_su1, stats{pairid}.prefered_sample_su2)];

                % 2. FC pairs (s1 trials)
                if isfield(stats{pairid}, 'AIs1') && stats{pairid}.AIs1 ~= 0
                    FCPair_s1 = PopulateFCpair(FCPair_s1, mouseid, learningday, region_pair, unitids, ...
                        stats{pairid}.AIs1, stats{pairid}.FRs1trials_su1(bin_id), stats{pairid}.FRs1trials_su2(bin_id), ...
                        stats{pairid}.prefered_sample_su1, stats{pairid}.prefered_sample_su2);
                end

                % 3. FC pairs (s2 trials)
                if isfield(stats{pairid}, 'AIs2') && stats{pairid}.AIs2 ~= 0
                    FCPair_s2 = PopulateFCpair(FCPair_s2, mouseid, learningday, region_pair, unitids, ...
                        stats{pairid}.AIs2, stats{pairid}.FRs2trials_su1(bin_id), stats{pairid}.FRs2trials_su2(bin_id), ...
                        stats{pairid}.prefered_sample_su1, stats{pairid}.prefered_sample_su2);
                end
                
            case 'Laser on off'
                % 1. All pairs (laser off)
                Pair_laseroff.mouse = [Pair_laseroff.mouse; mouseid];
                Pair_laseroff.learningday = [Pair_laseroff.learningday; learningday];
                Pair_laseroff.reg = [Pair_laseroff.reg; region_pair];
                Pair_laseroff.unitsid = [Pair_laseroff.unitsid; unitids];
                Pair_laseroff.FR.s1 = [Pair_laseroff.FR.s1; horzcat(stats{pairid}.FRs1trials_su1.laseroff(bin_id), stats{pairid}.FRs1trials_su2.laseroff(bin_id))];
                Pair_laseroff.FR.s2 = [Pair_laseroff.FR.s2; horzcat(stats{pairid}.FRs2trials_su1.laseroff(bin_id), stats{pairid}.FRs2trials_su2.laseroff(bin_id))];
                Pair_laseroff.preference = [Pair_laseroff.preference; horzcat(stats{pairid}.prefered_sample_su1.laseroff, stats{pairid}.prefered_sample_su2.laseroff)];

                % 2. All pairs (laser on)
                Pair_laseron.mouse = [Pair_laseron.mouse; mouseid];
                Pair_laseron.learningday = [Pair_laseron.learningday; learningday];
                Pair_laseron.reg = [Pair_laseron.reg; region_pair];
                Pair_laseron.unitsid = [Pair_laseron.unitsid; unitids];
                Pair_laseron.FR.s1 = [Pair_laseron.FR.s1; horzcat(stats{pairid}.FRs1trials_su1.laseron(bin_id), stats{pairid}.FRs1trials_su2.laseron(bin_id))];
                Pair_laseron.FR.s2 = [Pair_laseron.FR.s2; horzcat(stats{pairid}.FRs2trials_su1.laseron(bin_id), stats{pairid}.FRs2trials_su2.laseron(bin_id))];
                Pair_laseron.preference = [Pair_laseron.preference; horzcat(stats{pairid}.prefered_sample_su1.laseron, stats{pairid}.prefered_sample_su2.laseron)];

                % 3. FC pairs (s1 trials - laser off)
                if isfield(stats{pairid}, 'AIs1') && isfield(stats{pairid}.AIs1, 'laseroff') && stats{pairid}.AIs1.laseroff ~= 0
                    FCPair_s1_laseroff = PopulateFCpair(FCPair_s1_laseroff, mouseid, learningday, region_pair, unitids, ...
                        stats{pairid}.AIs1.laseroff, stats{pairid}.FRs1trials_su1.laseroff(bin_id), stats{pairid}.FRs1trials_su2.laseroff(bin_id), ...
                        stats{pairid}.prefered_sample_su1.laseroff, stats{pairid}.prefered_sample_su2.laseroff);
                end

                % 4. FC pairs (s2 trials - laser off)
                if isfield(stats{pairid}, 'AIs2') && isfield(stats{pairid}.AIs2, 'laseroff') && stats{pairid}.AIs2.laseroff ~= 0
                    FCPair_s2_laseroff = PopulateFCpair(FCPair_s2_laseroff, mouseid, learningday, region_pair, unitids, ...
                        stats{pairid}.AIs2.laseroff, stats{pairid}.FRs2trials_su1.laseroff(bin_id), stats{pairid}.FRs2trials_su2.laseroff(bin_id), ...
                        stats{pairid}.prefered_sample_su1.laseroff, stats{pairid}.prefered_sample_su2.laseroff);
                end

                % 5. FC pairs (s1 trials - laser on)
                if isfield(stats{pairid}, 'AIs1') && isfield(stats{pairid}.AIs1, 'laseron') && stats{pairid}.AIs1.laseron ~= 0
                    FCPair_s1_laseron = PopulateFCpair(FCPair_s1_laseron, mouseid, learningday, region_pair, unitids, ...
                        stats{pairid}.AIs1.laseron, stats{pairid}.FRs1trials_su1.laseron(bin_id), stats{pairid}.FRs1trials_su2.laseron(bin_id), ...
                        stats{pairid}.prefered_sample_su1.laseron, stats{pairid}.prefered_sample_su2.laseron);
                end

                % 6. FC pairs (s2 trials - laser on)
                if isfield(stats{pairid}, 'AIs2') && isfield(stats{pairid}.AIs2, 'laseron') && stats{pairid}.AIs2.laseron ~= 0
                    FCPair_s2_laseron = PopulateFCpair(FCPair_s2_laseron, mouseid, learningday, region_pair, unitids, ...
                        stats{pairid}.AIs2.laseron, stats{pairid}.FRs2trials_su1.laseron(bin_id), stats{pairid}.FRs2trials_su2.laseron(bin_id), ...
                        stats{pairid}.prefered_sample_su1.laseron, stats{pairid}.prefered_sample_su2.laseron);
                end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SAVE RESULTS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('Saving results for time window [%d %d]...\n', bin_start, bin_end);
    tic;
    switch analysismode
        case 'No laser'
            save_file = fullfile(basepath, sprintf('FCinformation_%s_%d_%d_%s.mat', binsize, bin_start, bin_end, group));
            save(save_file, 'Pair', 'FCPair_s1', 'FCPair_s2', '-v7.3');
        case 'Laser on off'
            save_file = fullfile(basepath, sprintf('FCinformation_%s_%d_%d_LaserOnOff.mat', binsize, bin_start, bin_end));
            save(save_file, 'Pair_laseroff', 'FCPair_s1_laseroff', 'FCPair_s2_laseroff', ...
                'Pair_laseron', 'FCPair_s1_laseron', 'FCPair_s2_laseron', '-v7.3');
    end
    toc;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HELPER FUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RegionCode = GetRegionCode(RegionName)
switch RegionName
    case 'left aAIC'
        RegionCode = 1;
    case 'right aAIC'
        RegionCode = 2;
    case 'left mPFC'
        RegionCode = 3;
    case 'right mPFC'
        RegionCode = 4;
    otherwise
        error(['Unknown region: ' RegionName]);
end
end

function FCpair = PopulateFCpair(FCpair, MouseID, LearningDayID, Region_pair, Unit_ids, AIvalue, FR_su1, FR_su2, Pref_su1, Pref_su2)
FCpair.mouse = [FCpair.mouse; MouseID];
FCpair.learningday = [FCpair.learningday; LearningDayID];
FCpair.reg = [FCpair.reg; Region_pair];
FCpair.unitsid = [FCpair.unitsid; Unit_ids];
FCpair.AI = [FCpair.AI; AIvalue];
FCpair.FR = [FCpair.FR; horzcat(FR_su1, FR_su2)];
FCpair.preference = [FCpair.preference; horzcat(Pref_su1, Pref_su2)];
end