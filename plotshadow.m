function plotshadow(data, C, IsSTDorSEM, SmoothWindow, Xshift, TimeGain)
% Plot mean time series with shaded error bands (STD/SEM/95%CI)
% INPUTS:
%   data            - Data matrix (nTrials×nBins)
%   C               - Plot color (RGB vector e.g., [1 0 0] or color string e.g., 'red')
%   IsSTDorSEM      - Error type: 1(STD)/2(SEM)/3(95% Confidence Interval)
%   SmoothWindow    - Smoothing window size for time series
%   Xshift          - Horizontal shift for x-axis (adjusts time offset)
%   TimeGain        - Scaling factor for x-axis (converts bins to time units)
% OUTPUT:
%   Plots mean time series + shaded error band; no return value

%% 1. Input validation
if ~ismatrix(data) || size(data,1) < 2
    error('Input "data" must be a matrix with ≥2 trials (rows) and ≥1 bin (columns)');
end
if ~ismember(IsSTDorSEM, [1,2,3])
    error('Input "IsSTDorSEM" must be 1(STD), 2(SEM), or 3(95%CI)');
end

%% 2. Core data
nBins = size(data, 2);
x = (1:nBins)/TimeGain + Xshift;  % X-axis (time units)
meanData = mean(data, 1);         % Trial-averaged data
smoothedMean = smooth(meanData, SmoothWindow);  % Smoothed mean

%% 3. Calculate error bounds (STD/SEM/95%CI)
switch IsSTDorSEM
    case 1  % Standard Deviation (STD)
        err = std(data, 0, 1);  % STD across trials
        upperBound = smoothedMean + err;
        lowerBound = smoothedMean - err;
    
    case 2  % Standard Error of Mean (SEM)
        nTrials = size(data, 1);
        err = std(data, 0, 1)/sqrt(nTrials);  % SEM = STD/√n
        upperBound = smoothedMean + err;
        lowerBound = smoothedMean - err;
    
    case 3  % 95% Confidence Interval (percentile-based)
        ci = prctile(data, [2.5, 97.5], 1);  % 2.5th/97.5th percentiles
        upperBound = smooth(ci(2,:), SmoothWindow);
        lowerBound = smooth(ci(1,:), SmoothWindow);
end

%% 4. Plot mean line + shaded error band
% Plot smoothed mean time series
plot(x, smoothedMean, 'Color', C, 'LineWidth', 2);
hold on;

% Create closed polygon for shaded area
timeVec = [x, fliplr(x)];  % X: original + reversed
valueVec = [upperBound, fliplr(lowerBound)];  % Y: upper + reversed lower

% Fill shaded error band (no edge, 20% transparency)
fill(timeVec, valueVec, C, 'EdgeColor', 'none', 'FaceAlpha', 0.2);

%% 5. Plot formatting
box off;
hold on;  % Retain original hold state for subsequent plotting

end