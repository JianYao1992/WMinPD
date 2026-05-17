function PlotEventCurve(SampleOnsetTime, SampleOdorLength, DelayLength, TestOdorLength, ResponseWindow, PlotMode, MaxYvalue)
% Plot task event markers (dotted lines) or shaded regions for trial phases
% INPUTS:
%   SampleOnsetTime   - Start time of sample odor phase (seconds)
%   SampleOdorLength  - Duration of sample odor phase (seconds)
%   DelayLength       - Duration of delay phase (seconds)
%   TestOdorLength    - Duration of test odor phase (seconds)
%   ResponseWindow    - Duration of response window (seconds)
%   PlotMode          - Plot type: 1(dotted lines for all events)/2(shaded regions + response dotted line)
%   MaxYvalue         - Maximum y-axis value (for shaded region height)
% OUTPUT:
%   Plots task event markers; no return value

%% 1. Input validation (enhance robustness)
if ~ismember(PlotMode, [1,2])
    error('Input "PlotMode" must be 1 (dotted lines) or 2 (shaded regions)');
end
if MaxYvalue <= 0
    error('Input "MaxYvalue" must be a positive number (maximum y-axis value)');
end

%% 2. Precompute all event timestamps (vectorized, no redundant calculation)
eventTimes = [
    SampleOnsetTime;  % Start of sample odor
    SampleOnsetTime + SampleOdorLength;  % End of sample odor (start of delay)
    SampleOnsetTime + SampleOdorLength + DelayLength;  % End of delay (start of test odor)
    SampleOnsetTime + SampleOdorLength + DelayLength + TestOdorLength;  % End of test odor
    SampleOnsetTime + SampleOdorLength + DelayLength + TestOdorLength + ResponseWindow  % End of response window
];

%% 3. Plot based on mode (dotted lines / shaded regions)
hold on;  % Ensure compatibility with overlay plotting
lineProps = {'LineStyle', '--', 'Color', [0.5 0.5 0.5]};  % Reusable dotted line properties
shadeProps = {'Color', 'k', 'FaceAlpha', 0.2, 'EdgeColor', 'none'};  % Reusable shade properties

switch PlotMode
    case 1  % Mode 1: Dotted lines for all 5 events
        arrayfun(@(t) xline(t, lineProps{:}), eventTimes);  % Vectorized xline plotting
    
    case 2  % Mode 2: Shaded regions (sample + test) + dotted line (response end)
        % Shaded region: Sample odor phase
        patch([eventTimes(1); eventTimes(1); eventTimes(2); eventTimes(2)], ...
              [0; MaxYvalue; MaxYvalue; 0], shadeProps{:});
        % Shaded region: Test odor phase
        patch([eventTimes(3); eventTimes(3); eventTimes(4); eventTimes(4)], ...
              [0; MaxYvalue; MaxYvalue; 0], shadeProps{:});
        % Dotted line: End of response window
        xline(eventTimes(5), lineProps{:});
end

end