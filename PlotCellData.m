function PlotCellData(data,color_line,width_line,style_line,shape_marker,facecolor_marker,edgecolor_marker,size_marker,Xshift)

Aver_data = cellfun(@mean,data);
Sem_data = cellfun(@(x) std(x)./sqrt(size(x,1)),data,'UniformOutput',true);
errorbar((1:size(data,2))+Xshift,Aver_data,Sem_data,'color',color_line,'LineWidth',width_line,'LineStyle',style_line,'marker',shape_marker,'markerfacecolor',facecolor_marker,'markeredgecolor',edgecolor_marker,'markersize',size_marker);
hold on
end
