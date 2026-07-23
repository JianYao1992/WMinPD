function plotMedianAndConfidenceInterval(colorvalue,Xstart,data,halfwidth)

% for itr = 1:length(varargin)
%     data{1,itr} = varargin{itr}(:);
% end
data = data(:);
Medi = prctile(data,50,1);
plot([Xstart-halfwidth Xstart+halfwidth],[Medi Medi],'color',colorvalue); 
hold on
CI_s = prctile(data,[25 75],1); % 25% and 75% percentile
fill([Xstart-halfwidth Xstart-halfwidth Xstart+halfwidth Xstart+halfwidth],[CI_s(1) CI_s(2) CI_s(2) CI_s(1)],colorvalue,'FaceAlpha',0.5);
hold on
CI_l = prctile(data,[2.5 97.5],1); % 2.5% and 97.5% percentile
errorbar(Xstart,Medi,Medi-CI_l(1),CI_l(2)-Medi,'color',colorvalue,'marker','none'); hold on
hold on