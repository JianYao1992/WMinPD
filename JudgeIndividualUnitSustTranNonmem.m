function [SelecLenType, SelecConsistenceType, SigSelecPattern, Zstat, P, SigSelecValue, SigSelecBinID, DelaySelecLen] = JudgeIndividualUnitSustTranNonmem(PutaSigSelecPattern, PutaSigSelecBinID, FRinS1, FRinS2, BaselineLength, SampleLength, DelayLength, CalcuSelecBinsNum, TimeGain, WorkerNum)
% Classify neuronal coding persistence type (sustained/transient/non-memory) by delay-period selectivity
% INPUTS:
%   PutaSigSelecPattern     - putative significant selectivity pattern (1: S1>S2,2: S2>S1,0: non-selective)
%   PutaSigSelecBinID       - putative significant selectivity bin IDs (vector)
%   FRinS1/FRinS2           - firing rate matrices for S1/S2 trials (nTrials×nBins)
%   BaselineLength/SampleLength/DelayLength - task event durations (seconds)
%   CalcuSelecBinsNum       - bin number for selectivity calculation (per second)
% OUTPUTS:
%   SelecLenType            - coding persistence type: 'sustained'/'transient'/'non-memory'
%   SelecConsistenceType    - selectivity consistency: 'consistent'/'inconsistent'/'none'
%   SigSelecPattern         - significant selectivity pattern (updated from putative)
%   Zstat/P                 - statistical test results (from TransientCodingTest)
%   SigSelecValue           - significant selectivity values
%   SigSelecBinID           - significant selectivity bin IDs (filtered from putative)
%   DelaySelecLen           - length of significant selectivity in delay period (seconds)

%% Initialization
% calculate bin index range for delay period
binPerSec = TimeGain/CalcuSelecBinsNum;
delayBinStart = (BaselineLength + SampleLength)*binPerSec + 1;
delayBinEnd = (BaselineLength + SampleLength + DelayLength)*binPerSec;
PutaSigSelecPattern_Delay = PutaSigSelecPattern(delayBinStart:delayBinEnd); % delay-period pattern

% initialize default outputs
Zstat = [];
P = [];
SigSelecPattern = PutaSigSelecPattern;
SigSelecBinID = PutaSigSelecBinID;
DelaySelecLen = DelayLength;

%% Step 1: Classify neuronal coding persistence type by delay-period putative selectivity pattern
% case 1: sustained & consistent (all S1-preferred or all S2-preferred in delay period)
if isequal(PutaSigSelecPattern_Delay, ones(1, DelayLength)) || isequal(PutaSigSelecPattern_Delay, 2*ones(1, DelayLength))
    SelecLenType = 'Sustained';
    SelecConsistenceType = 'Consistent';

% case 2: sustained but inconsistent (all selective, mixed S1-preferred and S2-preferred)
elseif all(PutaSigSelecPattern_Delay ~= 0)
    SelecLenType = 'Transient';
    SelecConsistenceType = 'Inconsistent';

% case 3: non-memory (all non-selective in delay period)
elseif isequal(PutaSigSelecPattern_Delay, zeros(1, DelayLength))
    SelecLenType = 'Non-memory';
    SelecConsistenceType = 'none';
    DelaySelecLen = 0;

% case 4: putative transient → run statistical test
elseif nnz(PutaSigSelecPattern_Delay) >= 1 && nnz(PutaSigSelecPattern_Delay) < DelayLength
    [SelecLenType, SigSelecBinID, DelaySelecLen, Zstat, P] = TransientCodingTest(FRinS1, FRinS2, PutaSigSelecBinID, BaselineLength, SampleLength, DelayLength, CalcuSelecBinsNum, TimeGain, WorkerNum);
    % update pattern: set non-significant putative bins to 0
    SigSelecPattern(setdiff(PutaSigSelecBinID, SigSelecBinID)) = 0;
    % judge consistency for transient neurons
    if strcmp(SelecLenType, 'Non-memory')
        SelecConsistenceType = 'none';
    elseif strcmp(SelecLenType, 'Transient')
        SigSelecPattern_Delay = SigSelecPattern(delayBinStart:delayBinEnd); % updated delay-period pattern
        if ismember(1, SigSelecPattern_Delay) && ismember(2, SigSelecPattern_Delay)
            SelecConsistenceType = 'Inconsistent';
        else
            SelecConsistenceType = 'Consistent';
        end
    end
end

%% Step 2: Calculate significant selectivity values
SigSelecValue = zeros(1, size(FRinS1, 2));
if ~isempty(SigSelecBinID)
    for iBin = SigSelecBinID
        % define bin column range for current significant bin
        binStart = 2 + (iBin - 1)*CalcuSelecBinsNum;
        binEnd = 1 + iBin*CalcuSelecBinsNum;
        % extract S1/S2 firing rates and compute mean across trials
        frS1_mean = mean(mean(FRinS1(:, binStart:binEnd), 2));
        frS2_mean = mean(mean(FRinS2(:, binStart:binEnd), 2));
        % calculate selectivity value
        SigSelecValue(binStart:binEnd) = (frS1_mean - frS2_mean) / (frS1_mean + frS2_mean);
    end
end

end