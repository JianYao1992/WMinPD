%this code was used to compare difference(A-B) of TCT decoding
%CrossDayROCAna  AllUnitsOdorSelectivityAna PopulationHeatMap %PlotNDTDecodingResultsPermutationTest
%NDTPopulationDecoding  NDTDecodingAnaAccordingToPerformance TrialTypeAndLaserEffecsOnDecoding
%LaserEfeectsOnNDTDecodingAna TrialTypeAndLaserEffecsOnDecoding
clear;clc;close all;

GroupID1='TransientNeu-20-ExcAllRevNeu';
GroupID2='Non-SelectiveNeu-20';

DecodingTimes=1000;
CurrentPath=pwd;
SubPath=[{GroupID1};{GroupID2}];
CrossGroupDecodingResults=cell(1,2);
CrossGroupMeanDecodingResults=cell(1,2);
for iPath=1:2
    Path=[CurrentPath '\' SubPath{iPath,1}];
    cd(Path);
    
    AllDecodingFile=dir('*NDT*.mat');%Parameters.mat
    [RealCrossReSampleDecodingResults,~,~,~]=ConstruceRealDecodingResults(AllDecodingFile,DecodingTimes);
    CrossGroupDecodingResults{iPath}=RealCrossReSampleDecodingResults;
    
    RealCrossReSampleDecodingResults=mean(RealCrossReSampleDecodingResults,1);
    RealCrossReSampleDecodingResults=reshape(RealCrossReSampleDecodingResults,size(RealCrossReSampleDecodingResults,2),size(RealCrossReSampleDecodingResults,3));
    CrossGroupMeanDecodingResults{iPath}=RealCrossReSampleDecodingResults;
end
AllParametersFile=dir('*All Parameters*.mat');
load(AllParametersFile.name)
cd(CurrentPath)
%% calculate the difference of TCT decoding
DiffTCT=CrossGroupDecodingResults{1}-CrossGroupDecodingResults{2};

TestBinNum=size(CrossGroupMeanDecodingResults{1},2);
IsSigDiffTCT=zeros(size(DiffTCT,2),size(DiffTCT,3));
for iTrainBin=1:TestBinNum
    for iTestBin = 1:TestBinNum
        tempBinDiff=DiffTCT(:,iTrainBin,iTestBin);
        The95ConfidenceInterval=prctile(tempBinDiff,[97.5,2.5]);
        if The95ConfidenceInterval(1)*The95ConfidenceInterval(2)>0%no cross with zero
            IsSigDiffTCT(iTrainBin,iTestBin)=1;
        end
    end
end
%%
MeanDiffTCT=CrossGroupMeanDecodingResults{1}-CrossGroupMeanDecodingResults{2};
DiffTCTIsSig={IsSigDiffTCT};

TimeBinNumber=size(MeanDiffTCT,2);
ProceedingBinNum=bin_width/step_size;
X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
X=X+ProceedingBinNum*step_size/1000;

Marker=[GroupID1 '-' GroupID2];
figure
imagesc(X,X,MeanDiffTCT*100,[-20 20]);
hold on
significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
for iEvent = 1:length(significant_event_times)
    plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'), '--k','linewidth',1)
    plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)], '--k','linewidth',1)
end
PlotDiffIsSignificantMatrix=zeros(size(MeanDiffTCT));
PlotSigBinNum=length(find(X<=7));
PlotDiffIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)=PlotDiffIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)+IsSigDiffTCT(1:PlotSigBinNum,1:PlotSigBinNum);
contour(X,X,PlotDiffIsSignificantMatrix,[1 1],'-w','linewidth',1)
axis xy
colorbar('ytick',[-20 -10 0 10 20],'yticklabel',[-20 -10 0 10 20])
%axis([-0.5 7.2 -0.5 7.2])
set(gca,'xtick',[0 2 4 6], 'XTickLabel', [0 2 4 6],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6])
xlabel('Test time (s)','fontsize',12)
ylabel('Train time (s)','fontsize',12)
title('Difference of decoding','fontsize',14)
saveas(gcf,[Marker '-Diff TCT'],'fig')%
saveas(gcf,[Marker '-Diff TCT'],'png')%
close all
save(['DiffTCTWithBootstrapTest-' Marker],'GroupID1','GroupID2','CrossGroupDecodingResults','CrossGroupMeanDecodingResults','DiffTCT'...
    ,'MeanDiffTCT','IsSigDiffTCT','X','bin_width','step_size','OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','StartTime')