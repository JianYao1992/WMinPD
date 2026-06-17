function [TitleName,Classifier]=ConstructNDTDecodingTitle(TargetBrainID,Decodingclassifier,DecodingForSamTestDecisionTrialType...
    ,IsShffleDecoding,num_resample_runs,num_cv_splits,num_times_to_repeat_each_label_per_cv_split,num_neuron_ForDecoding...
    ,PickUpNeuronsWithOdorSelectivity,bin_width,IsNormalizedData,GroupID,LearningPhase,DayID...
    ,IsCorrectOrErrorOrAllTrials,IsExcludeNLNeurons,IsPlotTCTDecodingResults,step_size...
    ,AddSustainedNeuronWithSigBinNum,CellType,PairOrNonPairTrials)

if DecodingForSamTestDecisionTrialType==1
    TitleName=['NDT-' TargetBrainID '-SampleOdor'];
elseif DecodingForSamTestDecisionTrialType==2;
    TitleName=['NDT-' TargetBrainID '-TestOdor'];
elseif DecodingForSamTestDecisionTrialType==3;
    TitleName=['NDT-' TargetBrainID '-Decision'];
elseif DecodingForSamTestDecisionTrialType==4    
    TitleName=['NDT-' TargetBrainID '-TrialType'];
end
TitleName=[TitleName '-' num2str(num_resample_runs) '-' num2str(num_cv_splits)...
    '-' num2str(num_times_to_repeat_each_label_per_cv_split) '-' num2str(bin_width) '-' num2str(step_size)];
if IsShffleDecoding==1
    TitleName=['Shuffle' TitleName];
end
TitleName=[TitleName '-' num2str(num_neuron_ForDecoding)];
if Decodingclassifier==1
    Classifier='MCC';
elseif Decodingclassifier==2
    Classifier='PNB';
elseif Decodingclassifier==3
    Classifier='SVM';
end
TitleName=[TitleName '-' Classifier '-' GroupID];

if PickUpNeuronsWithOdorSelectivity==1
    TitleName=[TitleName '-SelecNeu'];
end
if ~isempty(DayID)
    TitleName=[TitleName DayID];
end
if IsNormalizedData==1
    TitleName=[TitleName '-Norm'];
else
    TitleName=[TitleName '-Raw'];
end
if ~isempty(LearningPhase)
    TitleName=[TitleName '-' LearningPhase];
end
if IsCorrectOrErrorOrAllTrials==1
    TitleName=[TitleName '-CorrTri'];
elseif IsCorrectOrErrorOrAllTrials==2
    TitleName=[TitleName '-ErrorTri'];
elseif IsCorrectOrErrorOrAllTrials==3
    TitleName=[TitleName '-AllTri'];
end
if PairOrNonPairTrials==1
    TitleName=[TitleName '-PairTri'];
elseif PairOrNonPairTrials==2
    TitleName=[TitleName '-NonPairTri'];
end 
if IsExcludeNLNeurons==1
    TitleName=[TitleName '-ExcNeu'];
end
if IsPlotTCTDecodingResults==1
    TitleName=[TitleName '-TCT'];
end
if min(AddSustainedNeuronWithSigBinNum)>0&&max(AddSustainedNeuronWithSigBinNum)<=5
    TitleName=[TitleName '-AddSustEqual' num2str(AddSustainedNeuronWithSigBinNum)];
    TitleName=strrep(TitleName,'  ','-');
elseif AddSustainedNeuronWithSigBinNum==0
    TitleName=[TitleName '-NonSelectNeu'];
end
if CellType==2
    TitleName=[TitleName '-PC Neu'];
elseif CellType==3
    TitleName=[TitleName '-FSI Neu'];
end