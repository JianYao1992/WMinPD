%this code was used to compare the poolsize effects on the decoding increasement observed by add delay selective neurons with specific
%significant bin number
DecodingResultsFiles=dir('*AnaSustainNeuContriToDecoding*.mat');
%% plot the decoding increasement
PeriodMarkers=[{'Delay1'};{'Delay2'};{'Delay3'};{'Delay4'};{'Delay5'};{'WholeDelay'}];
AllTargetPeriodIncreaseCrossPoolSize=cell(1,length(PeriodMarkers));
for iPoolSize=1:size(DecodingResultsFiles,1)
    load(DecodingResultsFiles(iPoolSize).name)
    for iPeriod=1:length(PeriodMarkers)
        AllTargetPeriodIncreaseCrossPoolSize{1,iPeriod}=[AllTargetPeriodIncreaseCrossPoolSize{1,iPeriod};AllTargetPeriodIncreasePerNeuron(iPeriod,:)];
    end
end
%% plot pool size effects on decoding increasement
Colors = [[0 0 1];[0.5 0.5 1];[1 0.5 0.5];[1 0 0];[0 0 0]];
PoolSizeMarker=[{'PoolSize-100'};{'PoolSize-125'};{'PoolSize-150'};{'PoolSize-175'}];
for iPeriod=1:length(PeriodMarkers)
    PeriodID=PeriodMarkers{iPeriod};
    TargetPeriodDecodingIncreaseCrossPoolSize=AllTargetPeriodIncreaseCrossPoolSize{iPeriod};
    DelayBinNum=size(TargetPeriodDecodingIncreaseCrossPoolSize,2);
    YMax=max(max(TargetPeriodDecodingIncreaseCrossPoolSize));
    YMin=min(min(TargetPeriodDecodingIncreaseCrossPoolSize));
    figure
    for iPoolSize=1:size(TargetPeriodDecodingIncreaseCrossPoolSize,1)
        plot(1:DelayBinNum,TargetPeriodDecodingIncreaseCrossPoolSize(iPoolSize,:),'-*','color',Colors(iPoolSize,:),'linewidth',2,'markersize',8)
        hold on
    end
    h=legend(PoolSizeMarker);
    set(h,'location','northwest')
    if floor(YMax)==1
        YTick=0:0.25:1.25;
    else
        YTick=0:0.05:0.3;
    end
    set(gca,'xtick',[1 2 3 4 5],'xticklabel',[{'SigNeuBin1'};{'SigNeuBin2'};{'SigNeuBin3'};{'SigNeuBin4'};{'SigNeuBin5'}]...
        ,'ytick',YTick)
    axis([0.5 5.5 0 YMax*1.05])
    ylabel('Decoding increasement','fontsize',12)
    title(['PoolSize Effects on per neuron decoding increasement-' PeriodID],'fontsize',12)
    saveas(gcf,['PoolSize Effects on per neuron decoding increasement-' PeriodID],'fig')
    saveas(gcf,['PoolSize Effects on per neuron decoding increasement-' PeriodID],'png')
    close all
end