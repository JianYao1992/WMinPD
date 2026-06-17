%this code was used to compare multiple decoding results by excluding
%sustained odor selective neurons
clear;clc;close all;
AddSustainedNeuDir=[{'AddSust1'};{'AddSust2'};{'AddSust3'};{'AddSust4'};{'AddSust5'};{'NonSelec'}];
Legends=[{'AddNeuWithSigBin1'};{'AddNeuWithSigBin2'};{'AddNeuWithSigBin3'};{'AddNeuWithSigBin4'};{'AddNeuWithSigBin5'};{'NonSelectiveNeurons'}];
AllTargetNeuronIDWithSpecificSigBin=[1 2 3 4 5 6];

TotalDecodingTimes=50;

Path=pwd;
TimeGain=10;
Colors = [[0.7 0.7 1];[0.3 0.3 1];[0 0 1];[1 0.5 0.5];[1 0 0];[0 0 0]];

AllDecodingResults=cell(3,length(AddSustainedNeuDir));
NeuNumForSpecificSigBin=zeros(1,5);
for iNeuGroup=1:length(AddSustainedNeuDir)
    cd([Path '\' AddSustainedNeuDir{iNeuGroup}])
    DecodingResultsFiles=dir('*.mat');
    AddSustainedNeuronWithSigBinNum=AllTargetNeuronIDWithSpecificSigBin(iNeuGroup);
    
    FileName=DecodingResultsFiles(1).name;
    OdorID=regexpi(FileName,'Odor');
    MCCID=regexpi(FileName,'-MCC');
    DecodingParameters=FileName(OdorID+4:MCCID-1);
    StartTime=2;
    load(DecodingResultsFiles(1).name)
    CrossResampleDecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;
    BinNum=size(CrossResampleDecodingResults,3);
    CrossResampleDecodingResults=mean(CrossResampleDecodingResults,2);
    Size=size(CrossResampleDecodingResults);
    CrossResampleDecodingResults=reshape(CrossResampleDecodingResults,Size(1),Size(3));
    All_DECODING_RESULTS=zeros(TotalDecodingTimes,BinNum);
    All_DECODING_RESULTS(1:Size(1),:)=CrossResampleDecodingResults;
    StartDecodingTimes=Size(1);
    for iResult=2:size(DecodingResultsFiles,1)
        load(DecodingResultsFiles(iResult).name)
        CrossResampleDecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;
        CrossResampleDecodingResults=mean(CrossResampleDecodingResults,2);
        Size=size(CrossResampleDecodingResults);
        CrossResampleDecodingResults=reshape(CrossResampleDecodingResults,Size(1),Size(3));
        All_DECODING_RESULTS(StartDecodingTimes+1:StartDecodingTimes+Size(1),:)=CrossResampleDecodingResults;
        StartDecodingTimes=StartDecodingTimes+Size(1);

        if iResult==size(DecodingResultsFiles,1)
            PoolSizeID=regexpi(DecodingResultsFiles(iResult).name,'-All Parameters');
            PoolSize=DecodingResultsFiles(iResult).name(PoolSizeID-3:PoolSizeID-1);
            TargetNeuronIDWithSpecificSigBin=[];
            if min(AddSustainedNeuronWithSigBinNum)>=1&&max(AddSustainedNeuronWithSigBinNum)<=5
                for iNeuron=1:size(IsSustainedOdorSelectiveNeuron,1)
                    if sum(IsSustainedOdorSelectiveNeuron(iNeuron,:))==AddSustainedNeuronWithSigBinNum
                        TargetNeuronIDWithSpecificSigBin=union(TargetNeuronIDWithSpecificSigBin,iNeuron);
                    end
                end
                NeuNumForSpecificSigBin(iNeuGroup)=length(TargetNeuronIDWithSpecificSigBin);
            end
        end
    end
    if iNeuGroup==length(AddSustainedNeuDir)
        All_DECODING_RESULTS(51:end,:)=[];
    end
    AllDecodingResults{1,iNeuGroup}=All_DECODING_RESULTS;
    AllDecodingResults{2,iNeuGroup}=mean(All_DECODING_RESULTS);
    AllDecodingResults{3,iNeuGroup}=std(All_DECODING_RESULTS);
end
cd(Path)
YMax=zeros(1,length(AddSustainedNeuDir));
YMin=zeros(1,length(AddSustainedNeuDir));
for iNeuGroup=1:length(AddSustainedNeuDir)
    
    MeanDecodingResults=AllDecodingResults{2,iNeuGroup};
    curr_stdev_to_plot =AllDecodingResults{3,iNeuGroup};
    
    ProceedingBinNum=bin_width/step_size;
    TimeBinNumber=length(MeanDecodingResults);
    X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
    X=X+ProceedingBinNum*step_size/1000;
    if iNeuGroup==1
        AddLegend(Legends,Colors,'northeast')
    end
    hold on
    [y2,y1]=PlotMeanSEM(MeanDecodingResults,X,[Colors(iNeuGroup,:)*0.8;Colors(iNeuGroup,:)],curr_stdev_to_plot);%zeros(size(curr_stdev_to_plot))
    hold on
    YMax(iNeuGroup)=max(y1);
    YMin(iNeuGroup)=min(y2);
    if iNeuGroup==length(AddSustainedNeuDir)
        text(9.5,0.8,['NeuronNum=' num2str(num_neuron_ForDecoding)])
        plot([-2 2*OdorMN+DelayMN+ResponseMN+WaterMN+ITIMN-4],[0.5 0.5],'k','linewidth',2)
        EventCurve(OdorMN,DelayMN,ResponseMN,WaterMN,max(YMax),0.42);
        xlabel('Time from sample onset(s)','fontsize',12)
        ylabel('Decoding Accuracy','fontsize',12)
        set(gca,'fontsize',12,'TickDir','out')
        axis([-2 2*OdorMN+DelayMN+ResponseMN+WaterMN+ITIMN-4 0.4 min([max(YMax)*1.1 1])])
        box off
        title(['PoolSize-' PoolSize '-Decoding increasement by add delay selective neurons'],'fontsize',12)
        saveas(gcf,['PoolSize-' PoolSize '-Decoding increasement by add delay selective neurons time lampsed-STD'],'fig')%
        saveas(gcf,['PoolSize-' PoolSize '-Decoding increasement by add delay selective neurons time lampsed-STD'],'png')%
        %close all
    end
end
%% calculate the increasement after adding the selective neuron with specific significant one second bin number
Delay1=[OdorMN OdorMN+1];
Delay2=[OdorMN+1 OdorMN+2];
Delay3=[OdorMN+2 OdorMN+3];
Delay4=[OdorMN+3 OdorMN+4];
Delay5=[OdorMN+4 OdorMN+DelayMN];
WholeDelayPer=[OdorMN OdorMN+DelayMN];
AllPeriodToPlot=[{Delay1};{Delay2};{Delay3};{Delay4};{Delay5};{WholeDelayPer}];
NonSelectiveNeuronDecodingResults=AllDecodingResults{2,6};
AllTargetPeriodIncreasePerNeuron=zeros(length(AllPeriodToPlot),5);
AllTargetPeriodIncrease=cell(length(AllPeriodToPlot),1);
AllTargetPeriodIncreaseForEachResampleRun=cell(length(AllPeriodToPlot),1);
All2_5and97_5Percentile=cell(length(AllPeriodToPlot),1);
AllCrossGroupEachDecodingIncrasePerNeuDis=cell(length(AllPeriodToPlot),1);
for iPeriod=1:length(AllPeriodToPlot)
    TargetDelayPer=AllPeriodToPlot{iPeriod};
    TargetDelayPerBinID=find(X>TargetDelayPer(1)&X<=TargetDelayPer(2));
    
    TargetPeriodNonSelecNeuDecodingResults=NonSelectiveNeuronDecodingResults(TargetDelayPerBinID);
    %     plot(X([TargetDelayPerBinID(1) TargetDelayPerBinID(1)]),[0 1],'k','linewidth',2)
    %     plot(X([TargetDelayPerBinID(end) TargetDelayPerBinID(end)]),[0 1],'k','linewidth',2)
    DecodingIncreasement=zeros(5,length(TargetDelayPerBinID));
    TargetPeriodIncreaseForEachResampleRun=cell(1,5);
    temp2_5and97_5Percentile=zeros(2,5);
    CrossGroupEachDecodingIncrasePerNeuDis=zeros(TotalDecodingTimes,5);
    for iResult=1:5%go through each group of neurons with target significant delay one second bin
        DecodingResultsAddSpecificSigBin=AllDecodingResults{2,iResult};
        TargetPeriodDecodingResultsAddSpecificSigBin=DecodingResultsAddSpecificSigBin(TargetDelayPerBinID);
        DecodingIncreasement(iResult,:)=TargetPeriodDecodingResultsAddSpecificSigBin-TargetPeriodNonSelecNeuDecodingResults;
        
        EachDecodingResultsAddSpecificSigBin=AllDecodingResults{1,iResult};
        EachTargetPeriodDecodingResultsAddSpecificSigBin=EachDecodingResultsAddSpecificSigBin(:,TargetDelayPerBinID);
        EachDecodingIncreasement=EachTargetPeriodDecodingResultsAddSpecificSigBin-repmat(TargetPeriodNonSelecNeuDecodingResults,TotalDecodingTimes,1);
        EachDecodingIncrasePerNeuDis=sum(EachDecodingIncreasement,2)/NeuNumForSpecificSigBin(iResult);
        temp97_5Percentile= prctile(EachDecodingIncrasePerNeuDis,97.5);
        temp2_5Percentile= prctile(EachDecodingIncrasePerNeuDis,2.5);
        temp2_5and97_5Percentile(1,iResult)=temp97_5Percentile;
        temp2_5and97_5Percentile(2,iResult)=temp2_5Percentile;
        
        TargetPeriodIncreaseForEachResampleRun{iResult}=EachDecodingIncreasement;
        CrossGroupEachDecodingIncrasePerNeuDis(:,iResult)=EachDecodingIncrasePerNeuDis;
    end
    AllCrossGroupEachDecodingIncrasePerNeuDis{iPeriod}=CrossGroupEachDecodingIncrasePerNeuDis;
    AllTargetPeriodIncreaseForEachResampleRun{iPeriod}=TargetPeriodIncreaseForEachResampleRun;
    All2_5and97_5Percentile{iPeriod}=temp2_5and97_5Percentile;
    DecodingIncrasePerNeu=sum(DecodingIncreasement,2)'./NeuNumForSpecificSigBin;
    AllTargetPeriodIncreasePerNeuron(iPeriod,:)=DecodingIncrasePerNeu;
    AllTargetPeriodIncrease{iPeriod}=DecodingIncreasement;
end
%% plot the decoding increasement
PeriodMarkers=[{'Delay1'};{'Delay2'};{'Delay3'};{'Delay4'};{'Delay5'};{'WholeDelay'}];
Colors = [[0.7 0.7 1];[0.3 0.3 1];[0 0 1];[1 0.5 0.5];[1 0 0];[0 0 0]];
YMax=max(max(AllTargetPeriodIncreasePerNeuron));
YMin=min(min(AllTargetPeriodIncreasePerNeuron));
P=zeros(1,6);
for i=1:6
    figure
    AddLegend(PeriodMarkers(i),Colors(i,:),'northwest')
    hold on
    plot(1:DelayMN,AllTargetPeriodIncreasePerNeuron(i,:),'-*','color',Colors(i,:),'linewidth',2,'markersize',8)
    YMax=max(AllTargetPeriodIncreasePerNeuron(i,:));
    hold on
    temp2_5and97_5Percentile=All2_5and97_5Percentile{i};
    for iNeuGroup=1:5
        line([iNeuGroup iNeuGroup],temp2_5and97_5Percentile(:,iNeuGroup),'color',[0 0 0],'linewidth',2)
    end
    CrossGroupEachDecodingIncrasePerNeuDis=AllCrossGroupEachDecodingIncrasePerNeuDis{i};
    p=anova1(CrossGroupEachDecodingIncrasePerNeuDis,[],'off');
    P(i)=p;
    if p<0.001
        line([1 5],[YMax*1.17 YMax*1.17],'linewidth',2)
        plot(2.3,YMax*1.1,'*','color',[0 0 1],'markersize',10)
        plot(2.7,YMax*1.1,'*','color',[0 0 1],'markersize',10)
        plot(3,YMax*1.1,'*','color',[0 0 1],'markersize',10)
    elseif p<0.01
        line([1 5],[YMax*1.17 YMax*1.17],'linewidth',2)
        plot(2.3,YMax*1.1,'*','markersize',15)
        plot(2.5,YMax*1.1,'*','markersize',15)
    elseif p<0.05
        line([1 5],[YMax*1.17 YMax*1.17],'linewidth',2)
        plot(2.3,YMax*1.1,'*','markersize',15)
    end
    text(2.7,YMax,['p=' num2str(floor(p*10000)/10000)],'fontsize',12)
    YTick=SetTick(YMin,YMax);
    if i==6
        YTick=0:0.25:1.25;
    end
    set(gca,'xtick',[1 2 3 4 5],'xticklabel',[{'SigBinNum1'};{'SigBinNum2'};{'SigBinNum3'};{'SigBinNum4'};{'SigBinNum5'}]...
        ,'ytick',YTick)
    axis([0.5 5.5 0 YMax*1.20])
    ylabel('Decoding increasement','fontsize',12)
    box off
    title(['PoolSize-' PoolSize '-Decoding increasement per neuron by add delay selective neurons-' PeriodMarkers{i}],'fontsize',12)
    saveas(gcf,['PoolSize-' PoolSize '-Decoding increasement per neuron by add delay selective neurons-' PeriodMarkers{i}],'fig')
    saveas(gcf,['PoolSize-' PoolSize '-Decoding increasement per neuron by add delay selective neurons-' PeriodMarkers{i}],'png')
    close all
end
save(['AnaSustainNeuContriToDecoding-' PoolSize '-' num2str(TotalDecodingTimes)],'AllTargetPeriodIncreasePerNeuron'...
    ,'AllTargetPeriodIncrease','AllDecodingResults','X','PoolSize','StartTime','NeuNumForSpecificSigBin','All2_5and97_5Percentile'...
    ,'AllTargetPeriodIncreaseForEachResampleRun','AllCrossGroupEachDecodingIncrasePerNeuDis','P')