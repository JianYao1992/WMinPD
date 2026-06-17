%this code was used to analize the contribution of different neuron groups in decoding results
clear;clc;close all

DiffDecodingFiles=dir('*DiffDecodingWithBootstrapTest*.mat');
% NeuGroupMarker=[{'Day1-100'}];
NeuGroupMarker=[{'AllNeu-NDT-110'};{'ExcTrans-70'};{'ExcSus-70'};{'ExcSwitched-70'}];

NewDiffDecodingFiles=cell(size(NeuGroupMarker,1),1);
DiffDecodingFiles=struct2cell(DiffDecodingFiles);
DiffDecodingFiles=DiffDecodingFiles(1,:)';
for i=1:length(NeuGroupMarker)
    tempNeuGroup=NeuGroupMarker{i};
    T = regexpi(DiffDecodingFiles, tempNeuGroup);
    E = ~cellfun(@isempty, T);
    NewDiffDecodingFiles{i}=cell2mat(DiffDecodingFiles(E));
end
NeuMarkers=[{'AllNeu'};{'ExcTransientNeu'};{'ExcSustainedNeu'};{'ExcSwitchedNeu'}];

figure
AddLegend([{'ChR minus Control'};{'NpHR minus Control'}],[0 0 1;0 0.5 0])
hold on
for i=1:length(NewDiffDecodingFiles)
    load(NewDiffDecodingFiles{i})
    
    BoxPlot(ChRNLDiffDecoding*100,i-0.2,[0 0 1])
    hold on
    BoxPlot(NpHRNLDiffDecoding*100,i+0.2,[0 0.5 0])    
end
plot([0 length(NewDiffDecodingFiles)+0.5],[0 0],'--k')
xlim([0.5 length(NewDiffDecodingFiles)+0.5])
set(gca,'xtick',1:length(NewDiffDecodingFiles),'xticklabel',NeuMarkers)
ylabel('Difference of decoding (%)')
title('Diff decoding after removing diff. neu group')
saveas(gcf,'Diff decoding after removing diff neu group','fig')
saveas(gcf,'Diff decoding after removing dif neu group','png')
ResizeFigureForPaper('Diff decoding after removing diff neu group',[1.3 1],[0.5 length(NewDiffDecodingFiles)+0.5 -20 20]...
    ,0,1:length(NewDiffDecodingFiles),[-20 -10 0 10 20])
close all