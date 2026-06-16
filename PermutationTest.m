function ClusBasedPermuTestIsSig = PermutationTest(RealResults,NullDistributions)

%   Inputs:
%       RealResults - Observed results matrix (rows = observations, cols = test bins)
%       NullDistributions - Null distribution matrix (rows = permutations, cols = test bins)
%   Output:
%       ClusBasedPermuTestIsSig - Binary array (1 = significant at α=0.05, 0 = non-significant)

real_means = mean(RealResults,1);
[n_permutations, n_bins] = size(NullDistributions);

% Initialize output array
ClusBasedPermuTestIsSig = zeros(1, n_bins);

% Vectorized calculation of p-values
p_below = sum(NullDistributions < real_means,1) / n_permutations;
p_equal = sum(NullDistributions == real_means,1) / n_permutations;
p_above = sum(NullDistributions > real_means,1) / n_permutations;

% Define significance criteria (α = 0.05)
sig_criteria = (p_below <= 0.05) | ...
    (p_above <= 0.05) | ...
    ((p_below + p_equal) <= 0.05) | ...
    ((p_above + p_equal) <= 0.05);

% Convert logical significance to binary array
ClusBasedPermuTestIsSig(sig_criteria) = 1;
