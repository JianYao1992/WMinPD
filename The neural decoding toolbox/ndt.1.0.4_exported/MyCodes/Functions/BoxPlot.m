function BoxPlot(TempChRNLROI1DiffTCT,X1,BoxColor)

plot([X1-0.1 X1+0.1],[TempChRNLROI1DiffTCT(1) TempChRNLROI1DiffTCT(1)],'-k')%plot the median
hold on
plot([X1 X1],[TempChRNLROI1DiffTCT(3) TempChRNLROI1DiffTCT(2)],'--','color',BoxColor)%plot the 95th confidence interval
plot([X1-0.1 X1+0.1],[TempChRNLROI1DiffTCT(3) TempChRNLROI1DiffTCT(3)],'-','color',BoxColor)%plot the 2.5th percentile
plot([X1-0.1 X1+0.1],[TempChRNLROI1DiffTCT(2) TempChRNLROI1DiffTCT(2)],'-','color',BoxColor)%plot the 97.5th percentile
X1=[X1-0.1 X1+0.1 X1+0.1 X1-0.1];
Y1=[TempChRNLROI1DiffTCT(5) TempChRNLROI1DiffTCT(5) TempChRNLROI1DiffTCT(4) TempChRNLROI1DiffTCT(4)];%plot the 25th and 75the percentile
patch(X1,Y1,'w','facecolor','none','linestyle','-','linewidth',1,'EdgeColor',BoxColor)

