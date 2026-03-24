function metrics = CalculatePerfAfterRemovingUnmotivatedTrials(TrialStructure, SetTrialsNum, SetWindowNum, Threshold)
    % Function description:
    % Analyze behavioral data, remove trial window with poor hit rate, and calculate overall performance metrics
    %
    % Inputs：
    %   TrialStructure      - Trial structure matrix, where each row represents a trial. The last column is the outcome (1=Hit, 2=Miss, 3=FA, 4=CR)
    %   SetTrialsNum        - Total number of trials used to calculate window size (typically equal to the actual total number of trials).
    %   SetWindowNum        - Desired number of windows to divide the data into
    %   Threshold           - Hit rate threshold. Windows with a Hit rate below this value will be excluded
    %
    % Outputs：
    %   metrics                - A structure containing all calculated performance metrics (for the structure of trials after excluding windows with low hit rate) for easy access.


    % --------------------------
    %% 1. Initialization and parameter checks
    % --------------------------
    if nargin < 4
        error('Please provide all the required input parameters: TrialStructure, SetTrialsNum, SetWindowNum, Threshold');
    end
    
    total_trials = size(TrialStructure, 1);
    if total_trials == 0
        warning('The input TrialStructure is empty');
        metrics.NewTrialStructure = NaN;
        metrics.WindowHitRate = NaN;
        metrics.WindowMissRate = NaN;
        metrics.WindowFalseRate = NaN;
        metrics.WindowCRRate = NaN;
        metrics.WindowPerf = NaN;
        metrics.SessHitRate = NaN;
        metrics.SessMisssRate = NaN;
        metrics.SessFalseRate = NaN;
        metrics.SessCRRate = NaN;
        metrics.SessPerf = NaN;
        return;
    end

    % define outcomes to enhance code readability and maintainability
    RESULT_CODES.HIT = 1;
    RESULT_CODES.MISS = 2;
    RESULT_CODES.FA = 3;
    RESULT_CODES.CR = 4;

    % --------------------------
    %% 2. Calculate the window size and create window indices
    % --------------------------
    trials_per_window = fix(SetTrialsNum / SetWindowNum);
    
    % create start and end indices for each window to avoid redundant calculations within the loop
    window_starts = 1:trials_per_window:total_trials;
    window_ends = window_starts + trials_per_window - 1;
    if total_trials < window_ends(end) && total_trials - window_starts(end) < trials_per_window/2
        window_starts(end) = [];
        window_ends(end) = [];
    end
    % ensure the last window does not exceed the range
    window_ends(end) = min(window_ends(end), total_trials);
    
    num_windows = length(window_starts);

    % --------------------------
    %% 3. Preallocate arrays to improve efficiency
    % --------------------------
    % use a structure array to store the counts for each window for greater clarity
    window_counts(num_windows) = struct('Hits', 0, 'Misses', 0, 'FAs', 0, 'CRs', 0);
    HitRateinWindow = NaN(1, num_windows);
    MissRateinWindow = NaN(1, num_windows);
    FalseRateinWindow = NaN(1, num_windows);
    CRRateinWindow = NaN(1, num_windows);
    PerfinWindow = NaN(1, num_windows);

    % --------------------------
    %% 4. Iterate through the windows and calculate performance metrics
    % --------------------------
    for i = 1:num_windows
        start_idx = window_starts(i);
        end_idx = window_ends(i);
        
        % extract all results from the current window
        window_results = TrialStructure(start_idx:end_idx, end);
        
        window_counts(i).Hits = sum(window_results == RESULT_CODES.HIT);
        window_counts(i).Misses = sum(window_results == RESULT_CODES.MISS);
        window_counts(i).FAs = sum(window_results == RESULT_CODES.FA);
        window_counts(i).CRs = sum(window_results == RESULT_CODES.CR);
        
        % calculate various rates and be careful to avoid division by zero
        total_signals = window_counts(i).Hits + window_counts(i).Misses;
        if total_signals > 0
            HitRateinWindow(i) = 100 * window_counts(i).Hits / total_signals;
            MissRateinWindow(i) = 100 * window_counts(i).Misses / total_signals;
        end
        
        total_no_signals = window_counts(i).FAs + window_counts(i).CRs;
        if total_no_signals > 0
            FalseRateinWindow(i) = 100 * window_counts(i).FAs / total_no_signals;
            CRRateinWindow(i) = 100 * window_counts(i).CRs / total_no_signals;
        end
        
        total_trials_in_window = end_idx - start_idx + 1;
        if total_trials_in_window > 0
            PerfinWindow(i) = 100 * (window_counts(i).Hits + window_counts(i).CRs) / total_trials_in_window;
        end
    end

    % --------------------------
    %% 5. Identify and eliminate windows of low hit rate
    % --------------------------
    % find the window IDs where the hit rate is below the threshold
    below_thres_window_ids = find(HitRateinWindow <= Threshold);
    
    % create a logical vector to mark which trials need to be retained
    trials_to_keep = true(total_trials, 1);
    
    if ~isempty(below_thres_window_ids)
        for i = 1:length(below_thres_window_ids)
            window_id = below_thres_window_ids(i);
            % mark the trials within the windows with low hit rate as false (not retained)
            trials_to_keep(window_starts(window_id):window_ends(window_id)) = false;
        end
    end
    
    % apply filtering
    metrics.NewTrialStructure = TrialStructure(trials_to_keep, :);
    HitRateinWindow(below_thres_window_ids) = [];
    MissRateinWindow(below_thres_window_ids) = [];
    FalseRateinWindow(below_thres_window_ids) = [];
    CRRateinWindow(below_thres_window_ids) = [];
    PerfinWindow(below_thres_window_ids) = [];


    % --------------------------
    %% 6. Calculate the final session-level performance
    % --------------------------
    if isempty(metrics.NewTrialStructure)
        warning('All trials have ');
        HitRateinSession = NaN;
        MissRateinSession = NaN;
        FalseRateinSession = NaN;
        CRRateinSession = NaN;
        PerfinSession = NaN;
    else
        final_results = metrics.NewTrialStructure(:, end);
        
        hits_final = sum(final_results == RESULT_CODES.HIT);
        misses_final = sum(final_results == RESULT_CODES.MISS);
        fas_final = sum(final_results == RESULT_CODES.FA);
        crs_final = sum(final_results == RESULT_CODES.CR);
        
        total_signals_final = hits_final + misses_final;
        total_no_signals_final = fas_final + crs_final;
        total_trials_final = size(metrics.NewTrialStructure, 1);

        HitRateinSession = 100 * hits_final / total_signals_final;
        MissRateinSession = 100 * misses_final / total_signals_final;
        FalseRateinSession = 100 * fas_final / total_no_signals_final;
        CRRateinSession = 100 * crs_final / total_no_signals_final;
        PerfinSession = 100 * (hits_final + crs_final) / total_trials_final;
    end
    
    % --------------------------
    %% 7. Collate and output
    % --------------------------
    % package all output metrics into a struct to make the return value cleaner
    metrics.WindowHitRate = HitRateinWindow;
    metrics.WindowMissRate = MissRateinWindow;
    metrics.WindowFalseRate = FalseRateinWindow;
    metrics.WindowCRRate = CRRateinWindow;
    metrics.WindowPerf = PerfinWindow;
    
    metrics.SessHitRate = HitRateinSession;
    metrics.SessMissRate = MissRateinSession;
    metrics.SessFalseRate = FalseRateinSession;
    metrics.SessCRRate = CRRateinSession;
    metrics.SessPerf = PerfinSession;
    
end