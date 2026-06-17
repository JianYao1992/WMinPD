%this code was used to analize the contribution of different neuron groups in Cross-tempporal decoding results
clear;clc;close all

% ROI1Range=[5 6 5 6];
% ROI2Range=[1 2 3 6];
% ROI3Range=[3 6 1 2];
ROI1Range=[5 6 5 6];
ROI2Range=[2 3 4 6];
ROI3Range=[4 6 2 3];

DiffTCTFiles=dir('*DiffTCTWithBootstrapTest*.mat');
% NeuGroupMarker=[{'Day1-100'}];
NeuGroupMarker=[{'AllNeurons-450'};{'TransientNeu-20-ExcAllRevNeu'};{'SustainedNeu-30-ExcAllRevNeu'};{'Switched neurons-30'}];
% NeuGroupMarker=[{'AllNeurons'};{'AddSustEqual1-2'};{'AddSustEqual3-4-5'};{'Switched neurons'};{'NonSelectNeu'}];
% NeuGroupMarker=[{'AllNeurons'};{'ExcTransientNeu'};{'ExcSustainedNeu'};{'ExcAllReversedNeu'}];

NewDiffTCTFiles=cell(size(NeuGroupMarker,1),1);
DiffTCTFiles=struct2cell(DiffTCTFiles);
DiffTCTFiles=DiffTCTFiles(1,:)';
for i=1:length(NeuGroupMarker)
    tempNeuGroup=NeuGroupMarker{i};
    T = regexpi(DiffTCTFiles, tempNeuGroup);
    E = ~cellfun(@isempty, T);
    NewDiffTCTFiles{i}=cell2mat(DiffTCTFiles(E));
end
NeuMarkers=[{'AllNeu'};{'TransientNeu'};{'SustainedNeu'};{'SwitchedNeu'}];
ChRNLCrossGroupDiffTCT=cell(1,size(NewDiffTCTFiles,1));
ChRNLROI1MeanAnd95CI=zeros(5,size(NewDiffTCTFiles,1));
ChRNLROI23MeanAnd95CI=zeros(5,size(NewDiffTCTFiles,1));
NpHRNLCrossGroupDiffTCT=cell(1,size(NewDiffTCTFiles,1));
NpHRNLROI1MeanAnd95CI=zeros(5,size(NewDiffTCTFiles,1));
NpHRNLROI23MeanAnd95CI=zeros(5,size(NewDiffTCTFiles,1));
CrossGroupMeanChRNLDiff=cell(1,length(NewDiffTCTFiles));
CrossGroupMeanNpHRNLDiff=cell(1,length(NewDiffTCTFiles));
for i=1:length(NewDiffTCTFiles)
    load(NewDiffTCTFiles{i})
    
    CrossGroupMeanChRNLDiff{i}=MeanChRNLDiff;
    CrossGroupMeanNpHRNLDiff{i}=MeanNpHRNLDiff;
    %% calculate the Mean diff TCT decoding in ROI1 of ChR-Control diff-TCT
    [MeantempROI1ChRNLDiff,ChRNLROI1_95CI]=CalculateROITCT(ChRNLDiff,ROI1Range,X);
    ChRNLROI1MeanAnd95CI(:,i)=[median(MeantempROI1ChRNLDiff);ChRNLROI1_95CI'];
    
    %calculate the Mean diff TCT decoding in ROI2 of ChR-Control diff-TCT
    [MeantempROI2ChRNLDiff,~]=CalculateROITCT(ChRNLDiff,ROI2Range,X);
    %calculate the Mean diff TCT decoding in ROI3 of ChR-Control diff-TCT
    [MeantempROI3ChRNLDiff,~]=CalculateROITCT(ChRNLDiff,ROI3Range,X);
    MeanROI23ChRNLDiff=(MeantempROI2ChRNLDiff+MeantempROI3ChRNLDiff)/2;
    ChRNLROI23_95CI=prctile(MeanROI23ChRNLDiff,[97.5,2.5 75 25]);
    ChRNLROI23MeanAnd95CI(:,i)=[median(MeanROI23ChRNLDiff);ChRNLROI23_95CI'];
    
    ChRNLCrossGroupDiffTCT{i}=[MeantempROI1ChRNLDiff MeanROI23ChRNLDiff];
    %% calculate the Mean diff TCT decoding in ROI1 of NpHR-Control diff-TCT
    [MeantempROI1NpHRNLDiff,NpHRNLROI1_95CI]=CalculateROITCT(NpHRNLDiff,ROI1Range,X);
    NpHRNLROI1MeanAnd95CI(:,i)=[median(MeantempROI1NpHRNLDiff);NpHRNLROI1_95CI'];
    
    %calculate the Mean diff TCT decoding in ROI2 of NpHR-Control diff-TCT
    [MeantempROI2NpHRNLDiff,~]=CalculateROITCT(NpHRNLDiff,ROI2Range,X);
    %calculate the Mean diff TCT decoding in ROI3 of NpHR-Control diff-TCT
    [MeantempROI3NpHRNLDiff,~]=CalculateROITCT(NpHRNLDiff,ROI3Range,X);
    MeanROI23NpHRNLDiff=(MeantempROI2NpHRNLDiff+MeantempROI3NpHRNLDiff)/2;
    NpHRNLROI23_95CI=prctile(MeanROI23NpHRNLDiff,[97.5,2.5 75 25]);
    NpHRNLROI23MeanAnd95CI(:,i)=[median(MeanROI23NpHRNLDiff);NpHRNLROI23_95CI'];
    
    NpHRNLCrossGroupDiffTCT{i}=[MeantempROI1NpHRNLDiff MeanROI23NpHRNLDiff];
end

%% Calculate the proportion of bin number in Diff-TCT results with >0 and <0 in each neuron group
CalculateRange=[0 6];
TargetBinID=find(X>=CalculateRange(1)&X<CalculateRange(2));
ChRNLRatio=zeros(2,length(CrossGroupMeanChRNLDiff));
NpHRNLRatio=zeros(2,length(CrossGroupMeanChRNLDiff));
for i=1:length(CrossGroupMeanChRNLDiff)    
    
    MeanChRNLDiff=CrossGroupMeanChRNLDiff{i};
    MeanNpHRNLDiff=CrossGroupMeanNpHRNLDiff{i};
    
    TargetChRNLDiff=MeanChRNLDiff(TargetBinID,TargetBinID);
    ChRLargerNLBinNum=length(find(TargetChRNLDiff>0));
    ChRSmallerNLBinNum=length(find(TargetChRNLDiff<0));
    TargetNpHRNLDiff=MeanNpHRNLDiff(TargetBinID,TargetBinID);
    NpHRLargerNLBinNum=length(find(TargetNpHRNLDiff>0));
    NpHRSmallerNLBinNum=length(find(TargetNpHRNLDiff<0));
    TargetAreaBinNum=numel(TargetChRNLDiff);
    
    ChRNLRatio(:,i)=[ChRLargerNLBinNum ChRSmallerNLBinNum]/TargetAreaBinNum*100;
    NpHRNLRatio(:,i)=[NpHRLargerNLBinNum NpHRSmallerNLBinNum]/TargetAreaBinNum*100;     
end
LargerThanZeroRatio=[ChRNLRatio(1,:);NpHRNLRatio(1,:)];
SmallerThanZeroRatio=[ChRNLRatio(2,:);NpHRNLRatio(2,:)];

Colors=[[19 130 197]/255;[19 156 78]/255];
%% based on ChR-NL or NpHR-NL
AddLegend([{'DiffTCT>0'};{'DiffTCT<0'}],Colors,'NorthWest')
hold on
bar_handle =bar(1:size(ChRNLRatio,2),ChRNLRatio','grouped');
set(bar_handle(1),'FaceColor',Colors(1,:),'EdgeColor',Colors(1,:))
set(bar_handle(2),'FaceColor',Colors(2,:),'EdgeColor',Colors(2,:))
xlim([0.5 size(ChRNLRatio,2)+0.5])
set(gca,'xtick',1:size(ChRNLRatio,2),'xticklabel',NeuMarkers)
ylabel('Proportion (%)')
title('Diff TCT Diff Neu Larger_Smaller Ratio-ChR-NL')
saveas(gcf,'Diff TCT Diff Neu Larger_Smaller Ratio-ChR-NL','fig')
saveas(gcf,'Diff TCT Diff Neu Larger_Smaller Ratio-ChR-NL','png')
ResizeFigureForPaper('Diff TCT Diff Neu Larger_Smaller Ratio-ChR-NL',[1.36 1],[0.5 size(LargerThanZeroRatio,2)+0.5 0 75]...
    ,0,[1 2 3 4],[0 25 50 75])
close all

AddLegend([{'DiffTCT>0'};{'DiffTCT<0'}],Colors,'NorthWest')
hold on
bar_handle =bar(1:size(NpHRNLRatio,2),NpHRNLRatio','grouped');
set(bar_handle(1),'FaceColor',Colors(1,:),'EdgeColor',Colors(1,:))
set(bar_handle(2),'FaceColor',Colors(2,:),'EdgeColor',Colors(2,:))
xlim([0.5 size(NpHRNLRatio,2)+0.5])
set(gca,'xtick',1:size(NpHRNLRatio,2),'xticklabel',NeuMarkers)
ylim([0 100])
ylabel('Proportion (%)')
title('Diff TCT Diff Neu Larger_Smaller Ratio-NpHR-NL')
saveas(gcf,'Diff TCT Diff Neu Larger_Smaller Ratio-NpHR-NL','fig')
saveas(gcf,'Diff TCT Diff Neu Larger_Smaller Ratio-NpHR-NL','png')
ResizeFigureForPaper('Diff TCT Diff Neu Larger_Smaller Ratio-NpHR-NL',[1.36 1],[0.5 size(SmallerThanZeroRatio,2)+0.5 0 100]...
    ,0,[1 2 3 4],[0 25 50 75 100])
close all
%% based on >0 or <0
bar_handle =bar(1:size(LargerThanZeroRatio,2),LargerThanZeroRatio','grouped');
set(bar_handle(1),'FaceColor',Colors(1,:),'EdgeColor',Colors(1,:))
set(bar_handle(2),'FaceColor',Colors(2,:),'EdgeColor',Colors(2,:))
xlim([0.5 size(LargerThanZeroRatio,2)+0.5])
set(gca,'xtick',1:size(LargerThanZeroRatio,2),'xticklabel',NeuMarkers)
ylabel('Proportion (%)')
title('Diff TCT Larger Than Zero Bin Ratio')
saveas(gcf,'TCTLargerThanControlBinRatio-DiffNeuGroup','fig')
saveas(gcf,'TCTLargerThanControlBinRatio-DiffNeuGroup','png')
ResizeFigureForPaper('TCTLargerThanControlBinRatio-DiffNeuGroup',[1.36 1.3],[0.5 size(LargerThanZeroRatio,2)+0.5 0 70]...
    ,0,[1 2 3 4],[0 25 50 75])
close all

bar_handle =bar(1:size(SmallerThanZeroRatio,2),SmallerThanZeroRatio','grouped');
set(bar_handle(1),'FaceColor',Colors(1,:),'EdgeColor',Colors(1,:))
set(bar_handle(2),'FaceColor',Colors(2,:),'EdgeColor',Colors(2,:))
xlim([0.5 size(SmallerThanZeroRatio,2)+0.5])
set(gca,'xtick',1:size(SmallerThanZeroRatio,2),'xticklabel',NeuMarkers)
ylim([0 100])
ylabel('Proportion (%)')
title('Diff TCT Smaller Than Zero Bin Ratio')
saveas(gcf,'TCTSmallerThanControlBinRatio-DiffNeuGroup','fig')
saveas(gcf,'TCTSmallerThanControlBinRatio-DiffNeuGroup','png')
ResizeFigureForPaper('TCTSmallerThanControlBinRatio-DiffNeuGroup',[1.36 1.3],[0.5 size(SmallerThanZeroRatio,2)+0.5 0 100]...
    ,0,[1 2 3 4],[0 25 50 75 100])
close all
% %% plot the mean diff-TCT in ROI1
% ChRNLROI1MeanAnd95CI=ChRNLROI1MeanAnd95CI*100;
% NpHRNLROI1MeanAnd95CI=NpHRNLROI1MeanAnd95CI*100;
% ChRNLROI23MeanAnd95CI=ChRNLROI23MeanAnd95CI*100;
% NpHRNLROI23MeanAnd95CI=NpHRNLROI23MeanAnd95CI*100;
% 
% ROI1RangeMarker=num2str(ROI1Range);
% ROI1RangeMarker=strrep(ROI1RangeMarker,' ','');
% ROI2RangeMarker=num2str(ROI2Range);
% ROI2RangeMarker=strrep(ROI2RangeMarker,' ','');
% ROI3RangeMarker=num2str(ROI3Range);
% ROI3RangeMarker=strrep(ROI3RangeMarker,' ','');
% for i=1:length(NewDiffTCTFiles)
%     
%     TempChRNLROI1DiffTCT=ChRNLROI1MeanAnd95CI(:,i);
%     X=i-0.2;
%     AddLegend([{'ROI1 ChR minus NL'};{'ROI23 ChR minus NL'}],[[0 0 0];[0 0 1]])
%     hold on
%     plot([X-0.1 X+0.1],[TempChRNLROI1DiffTCT(1) TempChRNLROI1DiffTCT(1)],'-r')%plot the median
%     plot([X X],[TempChRNLROI1DiffTCT(3) TempChRNLROI1DiffTCT(2)],'--k')%plot the 95th confidence interval
%     plot([X-0.1 X+0.1],[TempChRNLROI1DiffTCT(3) TempChRNLROI1DiffTCT(3)],'-k')%plot the 2.5th percentile
%     plot([X-0.1 X+0.1],[TempChRNLROI1DiffTCT(2) TempChRNLROI1DiffTCT(2)],'-k')%plot the 97.5th percentile
%     X1=[X-0.1 X+0.1 X+0.1 X-0.1];
%     Y1=[TempChRNLROI1DiffTCT(5) TempChRNLROI1DiffTCT(5) TempChRNLROI1DiffTCT(4) TempChRNLROI1DiffTCT(4)];%plot the 25th and 75the percentile
%     patch(X1,Y1,'w','facecolor','none','linestyle','-','linewidth',1,'EdgeColor',[0 0 0])
%     
%     TempChRNLROI23DiffTCT=ChRNLROI23MeanAnd95CI(:,i);
%     X1=i+0.2;
%     plot([X1-0.1 X1+0.1],[TempChRNLROI23DiffTCT(1) TempChRNLROI23DiffTCT(1)],'-r')
%     plot([X1 X1],[TempChRNLROI23DiffTCT(3) TempChRNLROI23DiffTCT(2)],'--b')
%     plot([X1-0.1 X1+0.1],[TempChRNLROI23DiffTCT(2) TempChRNLROI23DiffTCT(2)],'-b')
%     plot([X1-0.1 X1+0.1],[TempChRNLROI23DiffTCT(3) TempChRNLROI23DiffTCT(3)],'-b')
%     X1=[X1-0.1 X1+0.1 X1+0.1 X1-0.1];
%     Y1=[TempChRNLROI23DiffTCT(5) TempChRNLROI23DiffTCT(5) TempChRNLROI23DiffTCT(4) TempChRNLROI23DiffTCT(4)];
%     patch(X1,Y1,'w','facecolor','none','linestyle','-','linewidth',1,'EdgeColor',[0 0 1])
% end
% plot([0 length(NewDiffTCTFiles)+1],[0 0],'--k')
% xlim([0.3 4.7])
% set(gca,'xtick',1:length(NewDiffTCTFiles),'xticklabel',NeuMarkers)
% xlabel('Different neuron group')
% ylabel('ChR-NL TCT decoding difference £¨%£©')
% title(['ChR-NL TCT difference-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker])
% saveas(gcf,['ChR-NL Diff-TCT-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'fig')
% saveas(gcf,['ChR-NL Diff-TCT-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'png')
% close all
% %% plot the mean diff-TCT in ROI23
% for i=1:length(NewDiffTCTFiles)
%     
%     TempNpHRNLROI1DiffTCT=NpHRNLROI1MeanAnd95CI(:,i);
%     X=i-0.2;
%     AddLegend([{'ROI1 NpHR minus NL'};{'ROI23 NpHR minus NL'}],[[0 0 0];[0 0 1]])
%     hold on
%     plot([X-0.1 X+0.1],[TempNpHRNLROI1DiffTCT(1) TempNpHRNLROI1DiffTCT(1)],'-r')%plot the median
%     plot([X X],[TempNpHRNLROI1DiffTCT(3) TempNpHRNLROI1DiffTCT(2)],'--k')%plot the 95th confidence interval
%     plot([X-0.1 X+0.1],[TempNpHRNLROI1DiffTCT(3) TempNpHRNLROI1DiffTCT(3)],'-k')%plot the 2.5th percentile
%     plot([X-0.1 X+0.1],[TempNpHRNLROI1DiffTCT(2) TempNpHRNLROI1DiffTCT(2)],'-k')%plot the 97.5th percentile
%     X1=[X-0.1 X+0.1 X+0.1 X-0.1];
%     Y1=[TempNpHRNLROI1DiffTCT(5) TempNpHRNLROI1DiffTCT(5) TempNpHRNLROI1DiffTCT(4) TempNpHRNLROI1DiffTCT(4)];%plot the 25th and 75the percentile
%     patch(X1,Y1,'w','facecolor','none','linestyle','-','linewidth',1,'EdgeColor',[0 0 0])
%     
%     TempNpHRNLROI23DiffTCT=NpHRNLROI23MeanAnd95CI(:,i);
%     X1=i+0.2;
%     plot([X1-0.1 X1+0.1],[TempNpHRNLROI23DiffTCT(1) TempNpHRNLROI23DiffTCT(1)],'-r')
%     hold on
%     plot([X1 X1],[TempNpHRNLROI23DiffTCT(3) TempNpHRNLROI23DiffTCT(2)],'--b')
%     plot([X1-0.1 X1+0.1],[TempNpHRNLROI23DiffTCT(2) TempNpHRNLROI23DiffTCT(2)],'-b')
%     plot([X1-0.1 X1+0.1],[TempNpHRNLROI23DiffTCT(3) TempNpHRNLROI23DiffTCT(3)],'-b')
%     X1=[X1-0.1 X1+0.1 X1+0.1 X1-0.1];
%     Y1=[TempNpHRNLROI23DiffTCT(5) TempNpHRNLROI23DiffTCT(5) TempNpHRNLROI23DiffTCT(4) TempNpHRNLROI23DiffTCT(4)];
%     patch(X1,Y1,'w','facecolor','none','linestyle','-','linewidth',1,'EdgeColor',[0 0 1])
% end
% plot([0 length(NewDiffTCTFiles)+1],[0 0],'--k')
% xlim([0.3 4.7])
% set(gca,'xtick',1:length(NewDiffTCTFiles),'xticklabel',NeuMarkers)
% xlabel('Different neuron group')
% ylabel('TCT decoding difference £¨%£©')
% title(['NpHR-NL Diff-TCT-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker])
% saveas(gcf,['NpHR-NL Diff-TCT-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'fig')
% saveas(gcf,['NpHR-NL Diff-TCT-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'png')
% close all