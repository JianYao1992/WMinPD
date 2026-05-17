function [UnitSelecLenType, SigSelecBinID, DelaySigSelecLen, Zstat, P] = TransientCodingTest(FRinS1, FRinS2, PutativeSigBinID, BaseLen, SampOdorLen, DelayLen, CalcuSelecBinsNum, TimeGain, WorkerNum)
% Statistical test for transient memory coding neurons in delay period
% INPUTS:
%   FRinS1/FRinS2           - firing rate for S1/S2 trials (nTrials×nBins)
%   PutativeSigBinID        - putative significant selectivity bin IDs (vector)
%   BaseLen/SampOdorLen/DelayLen - task event durations (seconds)
%   CalcuSelecBinsNum       - bin number for selectivity calculation (per second)
% OUTPUTS:
%   UnitSelecLenType        - coding persistence type: 'transient'/'non-memory'
%   SigSelecBinID           - Statistically significant selectivity bin IDs (sorted)
%   DelaySigSelecLen        - number of significant delay-phase bins
%   Zstat                   - Z-statistics from ranksum test (delay bins×delay bins)
%   P                       - P-values from permutation test (delay bins×delay bins)

%% 1. Initialization
binPerSec = TimeGain/CalcuSelecBinsNum;
delayBinStart = (BaseLen + SampOdorLen)*binPerSec + 1;
delayBinEnd = (BaseLen + SampOdorLen + DelayLen)*binPerSec;
DelayBinsID = delayBinStart:delayBinEnd;
nDelayBins = numel(DelayBinsID);
nTrialsS1 = size(FRinS1, 1);
nTrialsS2 = size(FRinS2, 1);

PermutationTimes = 2000;

% initialize output variables
SigSelecBinID = [];
Zstat = zeros(nDelayBins, nDelayBins);
P = zeros(nDelayBins, nDelayBins);
DelayBinnedFiringRateinS1 = zeros(nTrialsS1, nDelayBins);
DelayBinnedFiringRateinS2 = zeros(nTrialsS2, nDelayBins);

%% 2. Extract delay-period binned firing rates (S1/S2)
for iDelayBin = 1:nDelayBins
    frStart = TimeGain*(BaseLen + SampOdorLen + (iDelayBin-1)/binPerSec) + 2;
    frEnd = TimeGain*(BaseLen + SampOdorLen + iDelayBin/binPerSec) + 1;
    % mean firing rate across trials for current bin
    DelayBinnedFiringRateinS1(:,iDelayBin) = mean(FRinS1(:,frStart:frEnd), 2);
    DelayBinnedFiringRateinS2(:,iDelayBin) = mean(FRinS2(:,frStart:frEnd), 2);
end

%% 3. Calculate firing rate differences (reference bin × target bin × trial)
[refBin, tarBin] = meshgrid(1:nDelayBins, 1:nDelayBins);
DiffBinFRinS1 = reshape(DelayBinnedFiringRateinS1(:,refBin)' - DelayBinnedFiringRateinS1(:,tarBin)', nDelayBins, nDelayBins, nTrialsS1);
DiffBinFRinS2 = reshape(DelayBinnedFiringRateinS2(:,refBin)' - DelayBinnedFiringRateinS2(:,tarBin)', nDelayBins, nDelayBins, nTrialsS2);

%% 4. Ranksum test for real FR differences → Z-statistics
for iRef = 1:nDelayBins
    for iTar = 1:nDelayBins
        if iRef ~= iTar
            frDiffS1 = reshape(DiffBinFRinS1(iRef,iTar,:), 1, []);
            frDiffS2 = reshape(DiffBinFRinS2(iRef,iTar,:), 1, []);
            % ranksum test and extract Z-value
            [~,~,stats] = ranksum(frDiffS1, frDiffS2);
            Zstat(iRef,iTar) = stats.zval;
        end
    end
end

%% 5. Permutation test with parallel computing (2000 iterations)
% initialize parallel pool if not exists
poolobj = gcp('nocreate');
if isempty(poolobj)
    myCluster = parcluster('local');
    myCluster.NumWorkers = WorkerNum;
    parpool(myCluster, WorkerNum);
end

% preallocate shuffled Z-stat matrix (3D: ref×tar×permutation)
ShuffledZstat = zeros(nDelayBins, nDelayBins, PermutationTimes);
% run parallel permutation calculation
f = parfeval(@ComputeFRDiffScoreForPermutation, 1, DelayBinnedFiringRateinS1, DelayBinnedFiringRateinS2, nDelayBins);
for iShuf = 1:PermutationTimes
    [~, tempShuffledZ] = fetchNext(f);
    ShuffledZstat(:,:,iShuf) = tempShuffledZ;
end

%% 6. Calculate permutation test p-values & significance
IsSigHigherThanChance = false(nDelayBins, nDelayBins);
IsSigLessThanChance = false(nDelayBins, nDelayBins);
shufZmean = mean(ShuffledZstat, 3); % mean shuffled Z for each ref-tar pair

for iRef = 1:nDelayBins
    for iTar = 1:nDelayBins
        if Zstat(iRef,iTar) >= shufZmean(iRef,iTar)
            % P-value for Z > shuffled Z
            P(iRef,iTar) = sum(ShuffledZstat(iRef,iTar,:) > Zstat(iRef,iTar)) / PermutationTimes;
            IsSigHigherThanChance(iRef,iTar) = (P(iRef,iTar) <= 0.05);
        else
            % P-value for Z < shuffled Z
            P(iRef,iTar) = sum(ShuffledZstat(iRef,iTar,:) < Zstat(iRef,iTar)) / PermutationTimes;
            IsSigLessThanChance(iRef,iTar) = (P(iRef,iTar) <= 0.05);
        end
    end
end
P(logical(eye(nDelayBins))) = 1; % set self-comparison p-value to 1 (no significance)

%% 7. Filter significant delay-period bins from putative bins
% isolate putative significant bins in delay period
PutativeDelaySigBinID = PutativeSigBinID(PutativeSigBinID >= delayBinStart & PutativeSigBinID <= delayBinEnd);
NonSelecDelayBinID = setdiff(DelayBinsID, PutativeDelaySigBinID); % Non-selective delay bins
% map bin ID to matrix index
binIdxMap = @(x) x - (delayBinStart - 1);

% step 7.1: identify sub-putative bins with statistical significance
SubPutativeDelaySigBinID = [];
for iPut = 1:numel(PutativeDelaySigBinID)
    putIdx = binIdxMap(PutativeDelaySigBinID(iPut));
    for iNon = 1:numel(NonSelecDelayBinID)
        nonIdx = binIdxMap(NonSelecDelayBinID(iNon));
        % check significance for non-selective ↔ putative bin pairs
        if P(nonIdx, putIdx) <= 0.05 || P(putIdx, nonIdx) <= 0.05
            SubPutativeDelaySigBinID = [SubPutativeDelaySigBinID, PutativeDelaySigBinID(iPut)];
        end
    end
end
SubPutativeDelaySigBinID = unique(SubPutativeDelaySigBinID); % remove duplicates

% Step 7.2: classify neuron type & finalize significant bins
if isempty(SubPutativeDelaySigBinID)
    % no significant delay bins → non-memory
    UnitSelecLenType = 'Non-memory';
    DelaySigSelecLen = 0;
    % remove delay-phase putative bins from original list
    SigSelecBinID = PutativeSigBinID(~(PutativeSigBinID >= delayBinStart & PutativeSigBinID <= delayBinEnd));
else
    % update non-selective bins (add non-significant putative bins)
    NewNoSigBinID = setdiff(PutativeDelaySigBinID, SubPutativeDelaySigBinID);
    NonSelecDelayBinID = unique([NonSelecDelayBinID, NewNoSigBinID]);
    
    % extract final significant bins from sub-putative bins
    for iNon = 1:numel(NonSelecDelayBinID)
        nonIdx = binIdxMap(NonSelecDelayBinID(iNon));
        for iSub = 1:numel(SubPutativeDelaySigBinID)
            subIdx = binIdxMap(SubPutativeDelaySigBinID(iSub));
            if P(nonIdx, subIdx) <= 0.05 || P(subIdx, nonIdx) <= 0.05
                SigSelecBinID = [SigSelecBinID, SubPutativeDelaySigBinID(iSub)];
            end
        end
    end
    % intersect with original putative bins & remove duplicates
    SigSelecBinID = unique(intersect(PutativeSigBinID, SigSelecBinID));
    
    % final neuron classification
    if ~isempty(SigSelecBinID)
        UnitSelecLenType = 'Transient';
        DelaySigSelecLen = numel(SigSelecBinID);
    else
        UnitSelecLenType = 'Non-memory';
        DelaySigSelecLen = 0;
    end
    % merge non-delay putative bins + significant delay bins & sort
    nonDelayPutativeBinID = PutativeSigBinID(~(PutativeSigBinID >= delayBinStart & PutativeSigBinID <= delayBinEnd));
    SigSelecBinID = sort([nonDelayPutativeBinID, SigSelecBinID]);
end

end