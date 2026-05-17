function zvalue_perm = ComputeFRDiffScoreForPermutation(BinnedFRinS1, BinnedFRinS2, BinsNum)
% Calculate permuted Z-statistics via shuffled time bins
% INPUTS:
%   BinnedFRinS1/S2  - Binned firing rate matrices (nTrials×nBins) for S1/S2 trials (delay period only)
%   BinsNum          - Total number of delay-period bins (scalar)
% OUTPUT:
%   zvalue_perm      - Permuted Z-statistics matrix (nBins×nBins) from ranksum test (self-comparison = 0)

%% 1. Initialization & preallocate memory
nTrialsS1 = size(BinnedFRinS1, 1);  % number of S1 trials
nTrialsS2 = size(BinnedFRinS2, 1);  % number of S2 trials
% Preallocate FR difference arrays (3D: refBin×tarBin×trial)
DiffBinFRinS1 = zeros(BinsNum, BinsNum, nTrialsS1);
DiffBinFRinS2 = zeros(BinsNum, BinsNum, nTrialsS2);
% Initialize output Z-stat matrix (all zeros by default, self-comparison remains 0)
zvalue_perm = zeros(BinsNum, BinsNum);

%% 2. Calculate shuffled FR differences for S1 trials
for iTrial = 1:nTrialsS1
    tempTimeBin = randperm(BinsNum);  % shuffle time bin indices for permutation
    frShuf = BinnedFRinS1(iTrial, tempTimeBin);  % shuffled FR for current trial
    % vectorize ref-tar bin difference
    [refBin, tarBin] = meshgrid(1:BinsNum);
    DiffBinFRinS1(:, :, iTrial) = frShuf(refBin) - frShuf(tarBin);
end

%% 3. Calculate shuffled FR differences for S2 trials
for iTrial = 1:nTrialsS2
    tempTimeBin = randperm(BinsNum);  % shuffle time bin indices for permutation
    frShuf = BinnedFRinS2(iTrial, tempTimeBin);  % shuffled FR for current trial
    % vectorize ref-tar bin difference
    [refBin, tarBin] = meshgrid(1:BinsNum);
    DiffBinFRinS2(:, :, iTrial) = frShuf(refBin) - frShuf(tarBin);
end

%% 4. Ranksum test for permuted FR differences → Z-statistics
for iRef = 1:BinsNum
    for iTar = 1:BinsNum
        if iRef ~= iTar  % skip self-comparison (retain 0 in Z-stat matrix)
            % reshape FR differences to 1D vector for ranksum test
            frDiffS1 = reshape(DiffBinFRinS1(iRef, iTar, :), 1, []);
            frDiffS2 = reshape(DiffBinFRinS2(iRef, iTar, :), 1, []);
            % ranksum test and extract Z-value
            [~, ~, stats] = ranksum(frDiffS1, frDiffS2);
            zvalue_perm(iRef, iTar) = stats.zval;
        end
    end
end

end