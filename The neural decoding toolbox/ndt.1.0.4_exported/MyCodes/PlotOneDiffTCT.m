%this code was used to plot the difference of cross-temporal decoding and perform Bootsrap test
%PlotNDTDecodingResultsPermutationTest CompareMultipleDecodingResults
% PlotTCTDecodingPermutationTest PlotTCTTargetBin
clear;clc;close all;
ColorRange=[-20 20];
Color=[237 30 121]/255;%;

ROI1Range=[5 6 5 6];
ROI2Range=[2 3 4 6];
ROI3Range=[4 6 2 3];
AllROIs=[{ROI1Range};{ROI2Range};{ROI3Range}];
ROI1RangeMarker=num2str(ROI1Range);
ROI1RangeMarker=strrep(ROI1RangeMarker,' ','');
ROI2RangeMarker=num2str(ROI2Range);
ROI2RangeMarker=strrep(ROI2RangeMarker,' ','');
ROI3RangeMarker=num2str(ROI3Range);
ROI3RangeMarker=strrep(ROI3RangeMarker,' ','');

DiffTCTFile=dir('*DiffTCTWithBootstrapTest*.mat');%
AllDiffTCT=cell(1,size(DiffTCTFile,1));
DiffTCTIsSig=cell(1,size(DiffTCTFile,1));
%% plot Cross temporal decoding results with marker for significant time bin
for i=1:size(DiffTCTFile,1)    
    load(DiffTCTFile(i).name)
    AllDiffTCT{i}=MeanDiffTCT;
    DiffTCTIsSig{i}=IsSigDiffTCT;
    Marker=[GroupID1 '-' GroupID2];
    
    figure
    imagesc(X,X,MeanDiffTCT*100,ColorRange);
    hold on
    % extract and plot the boundary (X axis) of significant decoding in each training time line(Y axis)
    AllIsSignificantMatrix=zeros(size(MeanDiffTCT));
    PlotSigBinNum=length(find(X<=7));
    PlotSigBinRange=1:PlotSigBinNum;
    AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)=AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)...
        +IsSigDiffTCT(PlotSigBinRange,PlotSigBinRange);
    if sum(sum(AllIsSignificantMatrix))>2
        contour(X,X,AllIsSignificantMatrix,[1 1],'-','color',Color,'linewidth',1)
    end
    significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
    for iEvent = 1:length(significant_event_times)
        plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)
        plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
    end
    axis xy
    colorbar('ytick',[-20 -10 0 10 20 30 40 50],'yticklabel',[-20 -10 0 10 20 30 40 50])
    set(gca,'xtick',[0 2 4 6], 'XTickLabel', [0 2 4 6],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6],'TickLength',[0.025, 0.025],'linewidth',1);
    axis([-0.5 7.2 -0.5 7.2])
    xlabel('Test time (s)','fontsize',12)
    ylabel('Train time (s)','fontsize',12)
    
    title(['TCT Diff-' Marker],'fontsize',14)
    saveas(gcf,['TCT Diff-' Marker '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'fig')%
    saveas(gcf,['TCT Diff-' Marker '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'png')%
    %% save in specific size for Adobe Illustrator
    ResizeFigureForPaper(['TCT Diff-' Marker],[1.36 1.3],[-0.5 7.2 -0.5 7.2],1,[-2 0 2 4 6 8],[-2 0 2 4 6 8])
    close all
end
%% Calculate the bin number with >0 diff TCT, and bin number with <0 diff TCT
CalculateRange=[0 7];
TargetBinID=find(X>=CalculateRange(1)&X<CalculateRange(2));
TargetROIDiff=MeanDiffTCT(TargetBinID,TargetBinID);
LargerThanZeroBinNum=length(find(TargetROIDiff>0));
SmallerThanZeroBinNum=length(find(TargetROIDiff<0));
TargetAreaBinNum=numel(TargetROIDiff);

[~,pLargerOrSmallerThanNL, ~,~] = prop_test([LargerThanZeroBinNum SmallerThanZeroBinNum], [TargetAreaBinNum TargetAreaBinNum], false);
LargerOrSamllerThanNLRatio=[LargerThanZeroBinNum SmallerThanZeroBinNum]/TargetAreaBinNum*100;

bar(1:2,LargerOrSamllerThanNLRatio)
xlim([0.3 2.7])
set(gca,'xtick',1:2,'xticklabel',[{'ChR-Control>0'};{'ChR-Control<0'}])
ylabel('Proportion (%)')
title(['TCTLargerThanControlBinRatio-' Marker])
saveas(gcf,['TCTLargerThanControlBinRatio-' Marker],'fig')
saveas(gcf,['TCTLargerThanControlBinRatio-' Marker],'png')
ResizeFigureForPaper(['TCTLargerThanControlBinRatio-' Marker],[0.8 1],[0.3 2.7 0 50],0,[1 2],[0 10 20 30 40 50])
close all
%%
ROIMeanAnd95CI=zeros(5,2);
%% calculate the Mean diff TCT decoding in ROI1 of ChR-Control diff-TCT
[MeantempROI1Diff,ROI1_95CI]=CalculateROITCT(DiffTCT,ROI1Range,X);
ROIMeanAnd95CI(:,1)=[median(MeantempROI1Diff);ROI1_95CI'];

%calculate the Mean diff TCT decoding in ROI2 of ChR-Control diff-TCT
[MeantempROI2Diff,~]=CalculateROITCT(DiffTCT,ROI2Range,X);
%calculate the Mean diff TCT decoding in ROI3 of ChR-Control diff-TCT
[MeantempROI3Diff,~]=CalculateROITCT(DiffTCT,ROI3Range,X);
MeanROI23Diff=(MeantempROI2Diff+MeantempROI3Diff)/2;
ROI23_95CI=prctile(MeanROI23Diff,[97.5,2.5 75 25]);
ROIMeanAnd95CI(:,2)=[median(MeanROI23Diff);ROI23_95CI'];

ROIMeanAnd95CI=ROIMeanAnd95CI*100;
%% Plot the diff-TCT in ROIs
TempROI1DiffTCT=ROIMeanAnd95CI(:,1);
X1=1-0.2;
AddLegend([{'ROI1 ChR minus NL'};{'ROI23 ChR minus NL'}],[[0 0 0];[0 0 1]])
hold on
plot([X1-0.1 X1+0.1],[TempROI1DiffTCT(1) TempROI1DiffTCT(1)],'-r')%plot the median
plot([X1 X1],[TempROI1DiffTCT(3) TempROI1DiffTCT(2)],'--k')%plot the 95th confidence interval
plot([X1-0.1 X1+0.1],[TempROI1DiffTCT(3) TempROI1DiffTCT(3)],'-k')%plot the 2.5th percentile
plot([X1-0.1 X1+0.1],[TempROI1DiffTCT(2) TempROI1DiffTCT(2)],'-k')%plot the 97.5th percentile
X1=[X1-0.1 X1+0.1 X1+0.1 X1-0.1];
Y1=[TempROI1DiffTCT(5) TempROI1DiffTCT(5) TempROI1DiffTCT(4) TempROI1DiffTCT(4)];%plot the 25th and 75the percentile
patch(X1,Y1,'w','facecolor','none','linestyle','-','linewidth',1,'EdgeColor',[0 0 0])

TempROI23DiffTCT=ROIMeanAnd95CI(:,2);
X1=1+0.2;
plot([X1-0.1 X1+0.1],[TempROI23DiffTCT(1) TempROI23DiffTCT(1)],'-r')
plot([X1 X1],[TempROI23DiffTCT(3) TempROI23DiffTCT(2)],'--b')
plot([X1-0.1 X1+0.1],[TempROI23DiffTCT(2) TempROI23DiffTCT(2)],'-b')
plot([X1-0.1 X1+0.1],[TempROI23DiffTCT(3) TempROI23DiffTCT(3)],'-b')
X1=[X1-0.1 X1+0.1 X1+0.1 X1-0.1];
Y1=[TempROI23DiffTCT(5) TempROI23DiffTCT(5) TempROI23DiffTCT(4) TempROI23DiffTCT(4)];
patch(X1,Y1,'w','facecolor','none','linestyle','-','linewidth',1,'EdgeColor',[0 0 1])

plot([0 2],[0 0],'--k')
xlim([0.3 1.7])
set(gca,'xtick',1,'xticklabel',GroupID)
xlabel('Different neuron group')
ylabel('TCT decoding difference £¨%£©')
title(['TCT difference-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker])
saveas(gcf,['Diff-TCT-' Marker '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'fig')
saveas(gcf,['Diff-TCT-' Marker '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'png')
ResizeFigureForPaper(['Diff-TCT-' Marker '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],[0.7 0.5],[0.3 1.7 -12 6]...
    ,0,1:2,[-15 -10 -5 0 5 10 15])
close all