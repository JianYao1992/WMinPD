function SetXYaxisProperty(Xtick_min,XtickInterval,Xtick_max,Xaxis_min,Xaxis_max,Xaxis_name,Ytick_min,YtickInterval,Ytick_max,Yaxis_min,Yaxis_max,Yaxis_name,Fontsize_ticklabel,Fontsize_axislabel)

if ~isempty(Xtick_min)
    set(gca,'XTick',Xtick_min:XtickInterval:Xtick_max,'XTickLabel',num2cell(Xtick_min:XtickInterval:Xtick_max),'FontName','Arial','FontSize',Fontsize_ticklabel,'xlim',[Xaxis_min Xaxis_max]);
else
    set(gca,'XTick',zeros(1,0),'FontName','Arial','FontSize',Fontsize_ticklabel,'xlim',[Xaxis_min Xaxis_max]);
end
if ~isempty(Ytick_min)
    set(gca,'YTick',Ytick_min:YtickInterval:Ytick_max,'YTickLabel',num2cell(Ytick_min:YtickInterval:Ytick_max),'FontName','Arial','FontSize',Fontsize_ticklabel,'ylim',[Yaxis_min Yaxis_max]);
else
    set(gca,'YTick',zeros(1,0),'FontName','Arial','FontSize',Fontsize_ticklabel,'ylim',[Yaxis_min Yaxis_max]);
end
if ~isempty(Xaxis_name)
    xlabel(Xaxis_name,'FontName','Arial','FontSize',Fontsize_axislabel);
end
if ~isempty(Yaxis_name)
    ylabel(Yaxis_name,'FontName','Arial','FontSize',Fontsize_axislabel);
end
hold on
