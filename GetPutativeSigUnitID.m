function [PutaSelecBinsID, PutaSigSelecPattern] = GetPutativeSigUnitID(FRinS1, FRinS2, BinNumForSelecAnalysis, SampOdorLen, DelayDuration, TestOdorLen, ShownBaseDura, ShownRespWindowDura, TimeGain)
% Identify putative significant selective bins/neurons via ranksum + multiple comparison for correction
% INPUTS:
%   FRinS1/FRinS2           - cell arrays of firing rates for S1/S2 trials (1 neuron)
%   BinNumForSelecAnalysis  - bin number for selectivity analysis (bin width for ranksum test)
%   BaseDura/SampOdorLen/DelayDuration/TestOdorLen - Task phase durations (seconds)
%   ShownBaseDura/ShownRespWindowDura - Visible baseline/response window durations (seconds)
%   IsForHitCR              - 0: Analyse S1/S2 trials; 1: Analyse Hit/CR trials
% OUTPUTS:
%   UnitsIDwithPutaSelec    - Indices of neurons with putative significant selectivity
%   PutaSelecBinsID         - Cell array (1×1) of selective bin IDs for each neuron
%   PutaSigSelecPattern     - Matrix (1×M) of selectivity pattern (0: no;1: S1>S2;2: S2>S1)

%% Initialization & parameter calculation
nNeurons = size(FRinS1, 2);                  % total number of neurons
nBins = floor(size(FRinS1{1,1}, 2)/BinNumForSelecAnalysis);
correction = floor(ShownBaseDura + SampOdorLen + DelayDuration + TestOdorLen + ShownRespWindowDura) * TimeGain / BinNumForSelecAnalysis; 
p_vals = zeros(nNeurons, nBins);             % ranksum p-values for each neuron/bin
p_corrvals = zeros(nNeurons, nBins);         % corrected p-values
PutaSigSelecPattern = zeros(nNeurons, nBins);% selectivity pattern matrix
PutaSelecBinsID = cell(1, nNeurons);         % Selective bin IDs for each neuron

%% Step 1: Calculate ranksum p-value and corrected p-value for each neuron/bin
for iNeu = 1:nNeurons
    disp('******Calculating putatively significant selectivity******');
    frS1 = FRinS1{iNeu};  % firing rate of current neuron (S1)
    frS2 = FRinS2{iNeu};  % firing rate of current neuron (S2)
    
    % loop over analysis bins to perform ranksum test
    for iBin = 1:nBins
        binStart = 2 + (iBin-1)*BinNumForSelecAnalysis;
        binEnd = 1 + iBin*BinNumForSelecAnalysis;
        
        % mean firing rate across trials for S1/S2 in current bin
        frS1_bin = mean(frS1(:, binStart:binEnd), 2);
        frS2_bin = mean(frS2(:, binStart:binEnd), 2);
        
        % ranksum test for S1 vs S2 firing rates
        p_vals(iNeu, iBin) = ranksum(frS1_bin, frS2_bin);
    end
    
    % correction for all bins of current neuron
    p_corrvals(iNeu, :) = p_vals(iNeu, :) * correction;
    
    %% Step 2: Judge selectivity pattern and extract significant bins (corrected p-value ≤ 0.05)
    sigBinIdx = p_corrvals(iNeu, :) <= 0.05;  % logical index of significant bins
    PutaSelecBinsID{iNeu} = find(sigBinIdx);  % extract significant bin IDs
    
    % calculate mean FR for S1/S2 in all bins
    frS1_binMean = arrayfun(@(x) mean(mean(frS1(:,2+(x-1)*BinNumForSelecAnalysis:1+x*BinNumForSelecAnalysis),2)), 1:nBins);
    frS2_binMean = arrayfun(@(x) mean(mean(frS2(:,2+(x-1)*BinNumForSelecAnalysis:1+x*BinNumForSelecAnalysis),2)), 1:nBins);
    
    % assign selectivity pattern: 1=S1>S2, 2=S2>S1 (only for significant bins)
    PutaSigSelecPattern(iNeu, sigBinIdx & (frS1_binMean > frS2_binMean)) = 1;
    PutaSigSelecPattern(iNeu, sigBinIdx & (frS1_binMean < frS2_binMean)) = 2;
end

end