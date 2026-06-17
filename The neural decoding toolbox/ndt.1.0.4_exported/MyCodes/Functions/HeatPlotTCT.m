function HeatPlotTCT(RealDecodingResults,X,ColorBarRange,OdorMN,DelayMN,ResponseMN,WaterMN,Title,ClusterBasedPermuTestIsSignificant)

if nargin==8
    ClusterBasedPermuTestIsSignificant=[];
end

imagesc(X,X,RealDecodingResults*100,ColorBarRange);
hold on
% extract and plot the boundary (X axis) of significant decoding in each training time line(Y axis)
AllIsSignificantMatrix=zeros(size(RealDecodingResults));
PlotSigBinNum=length(find(X<=7.5));
if sum(sum(ClusterBasedPermuTestIsSignificant))>0
    AllIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)=AllIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)+ClusterBasedPermuTestIsSignificant(1:PlotSigBinNum,1:PlotSigBinNum);
    contour(X,X,AllIsSignificantMatrix,[1 1],'-w','linewidth',1)
end
significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
for iEvent = 1:length(significant_event_times)
    plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'), '--k','linewidth',1)
    plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)], '--k','linewidth',1)
end
colorbar('ytick',[0 10 20 30 40 50 60 70 80],'yticklabel',[0 10 20 30 40 50 60 70 80])
set(gca,'xtick',[0 2 4 6], 'XTickLabel', [0 2 4 6],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6]);%add by CQ
axis([-0.5 7.2 -0.5 7.2])
axis xy
title(Title)