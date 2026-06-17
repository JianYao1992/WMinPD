function plotBarAndError(color,Xstart,data,style)

data = data(:);
Aver = mean(data);
bar(Xstart,Aver,0.6,'FaceColor',color,'EdgeColor',color); hold on
switch style
    case 1   % SEM plot
        Sem = std(data)/sqrt(size(data,1));
        errorbar(Xstart,Aver,Sem,'color',color); hold on
    case 2   % CI plot
        CI = prctile(data,[2.5 97.5],1);
        errorbar(Xstart,Aver,Aver-CI(1),CI(2)-Aver,'color',color,'marker','none'); hold on
    case 3   % STD plot
        Std = std(data);
        errorbar(Xstart,Aver,Std,'color',color); hold on
end
