%this code was used to analize the laser effects on cross day decoding results
clear;clc;close all
LaserEffectsFiles=dir('*LaserEffectsOnDecoding*.mat');
% TargetDayID=[{[1 2 3]};{[4 5]}];%;{3};{[4]};{[5]};{[6]};{[7]}define the group days used to perform decoding analysis
% XLabel=[{'Day1-2-3'};{'Day4-5'}];
TargetDayID=[{[1]};{[2]};{[3]};{[4 5]}];%;{3};{[4]};{[5]};{[6]};{[7]}define the group days used to perform decoding analysis
XLabel=[{'Day1'};{'Day2'};{'Day3'};{'Day4-5'}];

Legends=[{'ChR2'};{'No-Laser'};{'NpHR'}];
FaceColors=[[0.6 0.6 1];[0.4 0.4 0.4];[0.4 1 0.4]];
Colors=[[0 0 1];[0 0 0];[0 0.5 0]];
DecodingTimesToCompare=50;
TimeGain=10;
MeanDelayDecodingAccuracy=zeros(3,length(TargetDayID));
STD=zeros(3,length(TargetDayID));
CrossDayDecodingResults=cell(3,length(TargetDayID));
for iDay=1:size(LaserEffectsFiles,1)%go each day gorup
    load(LaserEffectsFiles(iDay).name)
    CrossDayDecodingResults(:,iDay)=LaserAndNLDecodingResults';
    WholeDelayMeanDecodingAccuracy=AllPeriodsMeanDecodingAccuracy{3};
    
    MeanDelayDecodingAccuracy(:,iDay)=mean(WholeDelayMeanDecodingAccuracy(1:DecodingTimesToCompare,:))';
    STD(:,iDay)=std(WholeDelayMeanDecodingAccuracy(1:DecodingTimesToCompare,:))';
end
%%
YMin=min(min(MeanDelayDecodingAccuracy-STD));
YMax=max(max(MeanDelayDecodingAccuracy+STD));
for isLaserGroup=1:3%ChR2, No Laser, and NpHR group
    plot(1:length(TargetDayID),MeanDelayDecodingAccuracy(isLaserGroup,:),'color',Colors(isLaserGroup,:),'linewidth',2,'markersize',8)
    hold on
    errorbar(1:length(TargetDayID),MeanDelayDecodingAccuracy(isLaserGroup,:),STD(isLaserGroup,:),'color',Colors(isLaserGroup,:),'linewidth',2)
end
legend(Legends,'location','best')
ylabel('Decoding accuracy','fontsize',12)
ylim([floor(YMin*100)/100 YMax*1.04])
set(gca,'xtick',1:length(TargetDayID),'xticklabel',XLabel(1:length(TargetDayID)))
title('Cross day delay decoding accuracy','fontsize',12)
saveas(gcf,'Cross day delay decoding accuracy','fig')%
saveas(gcf,'Cross day delay decoding accuracy','png')%
close all
%% plot cross day decoding results
AllAxis=zeros(1,length(TargetDayID));
YMin=zeros(3,length(TargetDayID));
YMax=zeros(3,length(TargetDayID));
figure('Position', [350, 100, 900, 800]);
for iDay=1:size(CrossDayDecodingResults,2)
    tempDecodingResults=CrossDayDecodingResults(:,iDay);
    
    XAxisID=iDay;YAxisID=0;
    if length(TargetDayID)==2
        AllAxis(iDay)=subplot('position',[0.08+(iDay-1)*0.44 0.1 0.4 0.8]);
    elseif length(TargetDayID)==3
        AllAxis(iDay)=subplot('position',[0.08+(XAxisID-1)*0.3 0.1 0.26 0.8]);
    elseif length(TargetDayID)==4
        if iDay>2
            XAxisID=iDay-2;
            YAxisID=1;
        end
        AllAxis(iDay)=subplot('position',[0.08+(XAxisID-1)*0.44 0.54+YAxisID*(-0.46) 0.4 0.36]);
    end
    for isLaserGroup=1:length(tempDecodingResults)%ChR2, No Laser, and NpHR group
        tempGroupDecoding=tempDecodingResults{isLaserGroup};
        WindowNum=size(tempGroupDecoding,2);
        ProceedingBinNum=bin_width/step_size;
        X=-(4-StartTime):step_size/1000:(WindowNum*step_size/1000-(4-StartTime))-step_size/1000;
        X=X+ProceedingBinNum*step_size/1000;   
        
        if isLaserGroup==1
            AddLegend([{'ChR'} {'No Laser'} {'NpHR'}],Colors,[0.8, 0.32, 0.1, 0.1],10)
        end
        hold on
        STD=std(tempGroupDecoding);
        [YMin1,YMax1]=PlotMeanSEM(tempGroupDecoding,X,[Colors(isLaserGroup,:)*0.6;Colors(isLaserGroup,:)],STD);
        YMin(isLaserGroup,iDay)=YMin1;
        YMax(isLaserGroup,iDay)=YMax1;
        if isLaserGroup==length(tempDecodingResults)
            text(3.5,max(YMax(:,iDay))*0.95,'NeuNum=100')
            EventCurve(OdorMN,DelayMN,ResponseMN,WaterMN,max(YMax(:,iDay))*1.2,min(YMin(:,iDay))-0.04,4);
        end
    end
    if iDay>=3
        xlabel('Time from sample onset(s)','fontsize',12)
    end
    if iDay==1||iDay==3
        ylabel('Decoding accuracy','fontsize',12)
    end
    Title=['Day' num2str(TargetDayID{iDay}) '-decoding'];
    title(Title,'fontsize',12)
    set(gca,'fontsize',10,'TickDir','out')
    box off
end
axis(AllAxis,[-2 2*OdorMN+DelayMN+1 0.40 1])
saveas(gcf,'Laser effects on cross day decoding accuracy','fig')%
saveas(gcf,'Laser effects on cross day decoding accuracy','png')%
close all