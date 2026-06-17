%this code was used to plot the difference of cross-temporal decoding and perform Bootsrap test
%PlotNDTDecodingResultsPermutationTest CompareMultipleDecodingResults
% PlotTCTDecodingPermutationTest PlotTCTTargetBin
clear;clc;close all;
ColorRange=[-20 20];
Color=[1 1 1];%[237 30 121]/255;

DiffTCTFile=dir('*DiffTCTWithBootstrapTest*.mat');%
load(DiffTCTFile.name)

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

DiffTCT=[{MeanChRNLDiff};{MeanNpHRNLDiff}];
DiffTCTIsSig=[{ChRNLDiffSignificance};{NpHRNLDiffSignificance}];
%% plot Cross temporal decoding results with marker for significant time bin
Marker=[{'ChR minus NL '};{'NpHR minus NL'}];
for i=1:length(DiffTCT)
    tempDiffTCT=DiffTCT{i};
    tempIsSig=DiffTCTIsSig{i};
    figure
    imagesc(X,X,tempDiffTCT*100,[-20 20]);
    hold on
    % extract and plot the boundary (X axis) of significant decoding in each training time line(Y axis)
    AllIsSignificantMatrix=zeros(size(tempDiffTCT));
    PlotSigBinNum=length(find(X<=7));
    PlotSigBinRange=1:PlotSigBinNum;
    AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)=AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)...
        +tempIsSig(PlotSigBinRange,PlotSigBinRange);
    if sum(sum(AllIsSignificantMatrix))>2
        contour(X,X,AllIsSignificantMatrix,[1 1],'-','color',Color,'linewidth',1)
    end
    %     for iTrain=1:size(AllIsSignificantMatrix,1)
    %        for iTest=1:size(AllIsSignificantMatrix,2)
    %             if AllIsSignificantMatrix(iTrain,iTest)==1
    %                plot(X(iTest),X(iTrain),'.w','markersize',5)
    %             end
    %        end
    %     end
    significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
    for iEvent = 1:length(significant_event_times)
        plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)
        plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
    end
    axis xy
    for j=1:length(AllROIs)%go though each ROI
        tempROI=AllROIs{j};
        X1=[tempROI(3:4) fliplr(tempROI(3:4))];
        Y1=[tempROI(1) tempROI(1) tempROI(2) tempROI(2)];
        patch(X1,Y1,'w','facecolor','none','linestyle','--','linewidth',1,'EdgeColor',[1 0 1])
    end
    colorbar('ytick',[-20 -10 0 10 20],'yticklabel',[-20 -10 0 10 20])
    set(gca,'xtick',[0 2 4 6], 'XTickLabel', [0 2 4 6],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6],'TickLength',[0.025, 0.025],'linewidth',1);
    axis([-0.5 7.2 -0.5 7.2])
    xlabel('Test time (s)','fontsize',12)
    ylabel('Train time (s)','fontsize',12)
    
    title([GroupID '-' Marker{i} '- TCT Diff'],'fontsize',14)
    saveas(gcf,['TCT Diff-' GroupID '-' Marker{i} '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'fig')%
    saveas(gcf,['TCT Diff-' GroupID '-' Marker{i} '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'png')%
    %% save in specific size for Adobe Illustrator
    ResizeFigureForPaper(['TCT Diff-' GroupID '-' Marker{i}],[1.4502 1.2685],[-0.5 7.2 -0.5 7.2],1,[-2 0 2 4 6 8],[-2 0 2 4 6 8])
    close all
end
%% Calculate the bin number with >0 diff TCT, and bin number with <0 diff TCT
CalculateRange=[0 7];
TargetBinID=find(X>=CalculateRange(1)&X<CalculateRange(2));

TargetChRNLDiff=MeanChRNLDiff(TargetBinID,TargetBinID);
ChRLargerNLBinNum=length(find(TargetChRNLDiff>0));
ChRSmallerNLBinNum=length(find(TargetChRNLDiff<0));
TargetNpHRNLDiff=MeanNpHRNLDiff(TargetBinID,TargetBinID);
NpHRLargerNLBinNum=length(find(TargetNpHRNLDiff>0));
NpHRSmallerNLBinNum=length(find(TargetNpHRNLDiff<0));
TargetAreaBinNum=numel(TargetChRNLDiff);

[~,pLargerThanNL, ~,~] = prop_test([ChRLargerNLBinNum NpHRLargerNLBinNum], [TargetAreaBinNum TargetAreaBinNum], false);
[~,pSmallerThanNL, ~,~] = prop_test([ChRSmallerNLBinNum NpHRSmallerNLBinNum], [TargetAreaBinNum TargetAreaBinNum], false);

LargerThanNLRatio=[ChRLargerNLBinNum NpHRLargerNLBinNum]/TargetAreaBinNum*100;
SamllerThanNLRatio=[ChRSmallerNLBinNum NpHRSmallerNLBinNum]/TargetAreaBinNum*100;

bar(1:2,LargerThanNLRatio)
xlim([0.3 2.7])
set(gca,'xtick',1:2,'xticklabel',[{'ChR-Control'};{'NpHR-Control'}])
ylabel('Proportion (%)')
title('TCTLargerThanControlBinRatio')
saveas(gcf,'TCTLargerThanControlBinRatio','fig')
saveas(gcf,'TCTLargerThanControlBinRatio','png')
ResizeFigureForPaper('TCTLargerThanControlBinRatio',[0.8 1],[0.3 2.7 0 50],0,[1 2],[0 10 20 30 40 50])
close all

bar(1:2,SamllerThanNLRatio)
xlim([0.3 2.7])
set(gca,'xtick',1:2,'xticklabel',[{'ChR-Control'};{'NpHR-Control'}])
ylabel('Proportion (%)')
title('TCTSmallerThanControlBinRatio')
saveas(gcf,'TCTSmallerThanControlBinRatio','fig')
saveas(gcf,'TCTSmallerThanControlBinRatio','png')
ResizeFigureForPaper('TCTSmallerThanControlBinRatio',[0.8 1],[0.3 2.7 0 100],0,[1 2],[0 20 40 60 80 100])
close all
%%
if length(DiffTCT)>1
    figure('position',[400 300 900,450])
    for i=1:length(DiffTCT)
        subplot('position',[0.07+(i-1)*0.43,0.09,0.38+(i-1)*0.06,0.78]);%[left bottom width height]
        tempDiffTCT=DiffTCT{i};
        tempIsSig=DiffTCTIsSig{i};
        imagesc(X,X,tempDiffTCT*100,[-20 20]);
        hold on
        % extract and plot the boundary (X axis) of significant decoding in each training time line(Y axis)
        AllIsSignificantMatrix=zeros(size(tempDiffTCT));
        PlotSigBinNum=length(find(X<=7));
        PlotSigBinRange=1:PlotSigBinNum;
        AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)=AllIsSignificantMatrix(PlotSigBinRange,PlotSigBinRange)...
            +tempIsSig(PlotSigBinRange,PlotSigBinRange);
        if sum(sum(AllIsSignificantMatrix))>2
            contour(X,X,tempIsSig,[1 1],'-','color',Color,'linewidth',1)
        end
        significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
        for iEvent = 1:length(significant_event_times)
            plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)
            plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
        end
        if i==2
            colorbar('ytick',[-20 -10 0 10 20],'yticklabel',[-20 -10 0 10 20])
        end
        set(gca,'xtick',[0 2 4 6], 'XTickLabel', [0 2 4 6],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6],'TickLength',[0.025, 0.025],'linewidth',1);
        axis([-0.5 7.2 -0.5 7.2])
        xlabel('Test time (s)','fontsize',12)
        ylabel('Train time (s)','fontsize',12)
        axis xy
        title([GroupID '-' Marker{i} '- TCT Diff'],'fontsize',14)
    end
    saveas(gcf,['TCT Diff-' GroupID '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'fig')%
    saveas(gcf,['TCT Diff-' GroupID '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'png')%
    close all
end
%%
CrossGroupDiffTCT=cell(1,2);
ChRNLROIMeanAnd95CI=zeros(5,2);
NpHRNLROIMeanAnd95CI=zeros(5,2);
%% calculate the Mean diff TCT decoding in ROI1 of ChR-Control diff-TCT
[MeantempROI1ChRNLDiff,ChRNLROI1_95CI]=CalculateROITCT(ChRNLDiff,ROI1Range,X);
ChRNLROIMeanAnd95CI(:,1)=[median(MeantempROI1ChRNLDiff);ChRNLROI1_95CI'];

%calculate the Mean diff TCT decoding in ROI2 of ChR-Control diff-TCT
[MeantempROI2ChRNLDiff,~]=CalculateROITCT(ChRNLDiff,ROI2Range,X);
%calculate the Mean diff TCT decoding in ROI3 of ChR-Control diff-TCT
[MeantempROI3ChRNLDiff,~]=CalculateROITCT(ChRNLDiff,ROI3Range,X);
MeanROI23ChRNLDiff=(MeantempROI2ChRNLDiff+MeantempROI3ChRNLDiff)/2;
ChRNLROI23_95CI=prctile(MeanROI23ChRNLDiff,[97.5,2.5 75 25]);
ChRNLROIMeanAnd95CI(:,2)=[median(MeanROI23ChRNLDiff);ChRNLROI23_95CI'];
%% calculate the Mean diff TCT decoding in ROI1 of NpHR-Control diff-TCT
[MeantempROI1NpHRNLDiff,NpHRNLROI1_95CI]=CalculateROITCT(NpHRNLDiff,ROI1Range,X);
NpHRNLROIMeanAnd95CI(:,1)=[median(MeantempROI1NpHRNLDiff);NpHRNLROI1_95CI'];

%calculate the Mean diff TCT decoding in ROI2 of NpHR-Control diff-TCT
[MeantempROI2NpHRNLDiff,~]=CalculateROITCT(NpHRNLDiff,ROI2Range,X);
%calculate the Mean diff TCT decoding in ROI3 of NpHR-Control diff-TCT
[MeantempROI3NpHRNLDiff,~]=CalculateROITCT(NpHRNLDiff,ROI3Range,X);
MeanROI23NpHRNLDiff=(MeantempROI2NpHRNLDiff+MeantempROI3NpHRNLDiff)/2;
NpHRNLROI23_95CI=prctile(MeanROI23NpHRNLDiff,[97.5,2.5 75 25]);
NpHRNLROIMeanAnd95CI(:,2)=[median(MeanROI23NpHRNLDiff);NpHRNLROI23_95CI'];

CrossGroupDiffTCT{1}=[MeantempROI1ChRNLDiff MeanROI23ChRNLDiff];
CrossGroupDiffTCT{2}=[MeantempROI1NpHRNLDiff MeanROI23NpHRNLDiff];

ChRNLROIMeanAnd95CI=ChRNLROIMeanAnd95CI*100;
NpHRNLROIMeanAnd95CI=NpHRNLROIMeanAnd95CI*100;
%% Plot the diff-TCT in ROIs
TempChRNLROI1DiffTCT=ChRNLROIMeanAnd95CI(:,1);
X1=1-0.2;
AddLegend([{'ROI1 ChR minus NL'};{'ROI23 ChR minus NL'}],[[0 0 0];[0 0 1]])
hold on
plot([X1-0.1 X1+0.1],[TempChRNLROI1DiffTCT(1) TempChRNLROI1DiffTCT(1)],'-r')%plot the median
plot([X1 X1],[TempChRNLROI1DiffTCT(3) TempChRNLROI1DiffTCT(2)],'--k')%plot the 95th confidence interval
plot([X1-0.1 X1+0.1],[TempChRNLROI1DiffTCT(3) TempChRNLROI1DiffTCT(3)],'-k')%plot the 2.5th percentile
plot([X1-0.1 X1+0.1],[TempChRNLROI1DiffTCT(2) TempChRNLROI1DiffTCT(2)],'-k')%plot the 97.5th percentile
X1=[X1-0.1 X1+0.1 X1+0.1 X1-0.1];
Y1=[TempChRNLROI1DiffTCT(5) TempChRNLROI1DiffTCT(5) TempChRNLROI1DiffTCT(4) TempChRNLROI1DiffTCT(4)];%plot the 25th and 75the percentile
patch(X1,Y1,'w','facecolor','none','linestyle','-','linewidth',1,'EdgeColor',[0 0 0])

TempChRNLROI23DiffTCT=ChRNLROIMeanAnd95CI(:,2);
X1=1+0.2;
plot([X1-0.1 X1+0.1],[TempChRNLROI23DiffTCT(1) TempChRNLROI23DiffTCT(1)],'-r')
plot([X1 X1],[TempChRNLROI23DiffTCT(3) TempChRNLROI23DiffTCT(2)],'--b')
plot([X1-0.1 X1+0.1],[TempChRNLROI23DiffTCT(2) TempChRNLROI23DiffTCT(2)],'-b')
plot([X1-0.1 X1+0.1],[TempChRNLROI23DiffTCT(3) TempChRNLROI23DiffTCT(3)],'-b')
X1=[X1-0.1 X1+0.1 X1+0.1 X1-0.1];
Y1=[TempChRNLROI23DiffTCT(5) TempChRNLROI23DiffTCT(5) TempChRNLROI23DiffTCT(4) TempChRNLROI23DiffTCT(4)];
patch(X1,Y1,'w','facecolor','none','linestyle','-','linewidth',1,'EdgeColor',[0 0 1])

plot([0 2],[0 0],'--k')
xlim([0.3 1.7])
set(gca,'xtick',1,'xticklabel',GroupID)
xlabel('Different neuron group')
ylabel('ChR-NL TCT decoding difference £¨%£©')
title(['ChR-NL TCT difference-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker])
saveas(gcf,['ChR-NL Diff-TCT-' GroupID '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'fig')
saveas(gcf,['ChR-NL Diff-TCT-' GroupID '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'png')
ResizeFigureForPaper(['ChR-NL Diff-TCT-' GroupID '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],[0.7 0.5],[0.3 1.7 -12 6]...
    ,0,1:2,[-15 -10 -5 0 5 10 15])
close all
%%
TempNpHRNLROI1DiffTCT=NpHRNLROIMeanAnd95CI(:,1);
X1=1-0.2;
AddLegend([{'ROI1 NpHR minus NL'};{'ROI23 NpHR minus NL'}],[[0 0 0];[0 0 1]])
hold on
plot([X1-0.1 X1+0.1],[TempNpHRNLROI1DiffTCT(1) TempNpHRNLROI1DiffTCT(1)],'-r')%plot the median
plot([X1 X1],[TempNpHRNLROI1DiffTCT(3) TempNpHRNLROI1DiffTCT(2)],'--k')%plot the 95th confidence interval
plot([X1-0.1 X1+0.1],[TempNpHRNLROI1DiffTCT(3) TempNpHRNLROI1DiffTCT(3)],'-k')%plot the 2.5th percentile
plot([X1-0.1 X1+0.1],[TempNpHRNLROI1DiffTCT(2) TempNpHRNLROI1DiffTCT(2)],'-k')%plot the 97.5th percentile
X1=[X1-0.1 X1+0.1 X1+0.1 X1-0.1];
Y1=[TempNpHRNLROI1DiffTCT(5) TempNpHRNLROI1DiffTCT(5) TempNpHRNLROI1DiffTCT(4) TempNpHRNLROI1DiffTCT(4)];%plot the 25th and 75the percentile
patch(X1,Y1,'w','facecolor','none','linestyle','-','linewidth',1,'EdgeColor',[0 0 0])

TempNpHRNLROI23DiffTCT=NpHRNLROIMeanAnd95CI(:,2);
X1=1+0.2;
plot([X1-0.1 X1+0.1],[TempNpHRNLROI23DiffTCT(1) TempNpHRNLROI23DiffTCT(1)],'-r')
hold on
plot([X1 X1],[TempNpHRNLROI23DiffTCT(3) TempNpHRNLROI23DiffTCT(2)],'--b')
plot([X1-0.1 X1+0.1],[TempNpHRNLROI23DiffTCT(2) TempNpHRNLROI23DiffTCT(2)],'-b')
plot([X1-0.1 X1+0.1],[TempNpHRNLROI23DiffTCT(3) TempNpHRNLROI23DiffTCT(3)],'-b')
X1=[X1-0.1 X1+0.1 X1+0.1 X1-0.1];
Y1=[TempNpHRNLROI23DiffTCT(5) TempNpHRNLROI23DiffTCT(5) TempNpHRNLROI23DiffTCT(4) TempNpHRNLROI23DiffTCT(4)];
patch(X1,Y1,'w','facecolor','none','linestyle','-','linewidth',1,'EdgeColor',[0 0 1])
plot([0 2],[0 0],'--k')
xlim([0.3 1.7])
set(gca,'xtick',1,'xticklabel',GroupID)
xlabel('Different neuron group')
ylabel('TCT decoding difference £¨%£©')
title(['NpHR-NL Diff-TCT-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker])
saveas(gcf,['NpHR-NL Diff-TCT-' GroupID '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'fig')
saveas(gcf,['NpHR-NL Diff-TCT-' GroupID '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],'png')
ResizeFigureForPaper(['NpHR-NL Diff-TCT-' GroupID '-' ROI1RangeMarker '-' ROI2RangeMarker '-' ROI3RangeMarker],[0.7 0.5],[0.3 1.7 -14 2]...
    ,0,1:2,[-15 -10 -5 0 5 10 15])
close all