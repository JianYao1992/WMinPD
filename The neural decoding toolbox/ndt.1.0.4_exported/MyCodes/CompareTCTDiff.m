%this code was used to compare difference(A-B) of TCT decoding
%CrossDayROCAna  AllUnitsOdorSelectivityAna PopulationHeatMap %PlotNDTDecodingResultsPermutationTest
%NDTPopulationDecoding  NDTDecodingAnaAccordingToPerformance TrialTypeAndLaserEffecsOnDecoding
%LaserEfeectsOnNDTDecodingAna TrialTypeAndLaserEffecsOnDecoding PlotDiffTCT
%PlotCQTCTDecoding CompareTwoTCTDiff
clear;clc;close all;

GroupID='SustainedNeu-30-ExcAllRevNeu';
DecodingTimes=1000;

CurrentPath=pwd;
AllPath=genpath(CurrentPath);
SplitPath=strsplit(AllPath,';');
SubPath=SplitPath';
SubPath=SubPath(1:end-1);
SubPath=ExcludeShuffleDir(SubPath);
SubPath=SubPath(2:end);
CrossGroupDecodingResults=cell(1,size(SubPath,1));
CrossGroupMeanDecodingResults=cell(1,size(SubPath,1));
CrossGroupBinNum=zeros(1,size(SubPath,1));
for iPath=1:size(SubPath,1)%go through each directory
    Path=SubPath{iPath,1};
    cd(Path);
    
    AllDecodingFile=dir('*Decoding*.mat');%Parameters.mat
%     AllDecodingFile=dir('*NDT*.mat');
    [RealCrossReSampleDecodingResults,~,~,~]=ConstruceRealDecodingResults(AllDecodingFile,DecodingTimes);
    CrossGroupDecodingResults{iPath}=RealCrossReSampleDecodingResults;
    
    RealCrossReSampleDecodingResults=mean(RealCrossReSampleDecodingResults,1);
    RealCrossReSampleDecodingResults=reshape(RealCrossReSampleDecodingResults,size(RealCrossReSampleDecodingResults,2),size(RealCrossReSampleDecodingResults,3));
    CrossGroupMeanDecodingResults{iPath}=RealCrossReSampleDecodingResults;
    CrossGroupBinNum(1,iPath)=size(RealCrossReSampleDecodingResults,2);
end
AllParametersFile=dir('*All Parameters*.mat');
load(AllParametersFile.name)
cd(SplitPath{1})
MinBinNum=min(CrossGroupBinNum);
X=X(1:MinBinNum);
MinBinNum=repmat({MinBinNum},size(CrossGroupDecodingResults));
CrossGroupDecodingResults=cellfun(@(x,y) x(:,1:y,1:y),CrossGroupDecodingResults,MinBinNum,'uniformoutput',0);
CrossGroupMeanDecodingResults=cellfun(@(x,y) x(1:y,1:y),CrossGroupMeanDecodingResults,MinBinNum,'uniformoutput',0);
%% calculate the difference of TCT decoding
ChRNLDiff=CrossGroupDecodingResults{1}-CrossGroupDecodingResults{2};
NpHRNLDiff=CrossGroupDecodingResults{3}-CrossGroupDecodingResults{2};

TestBinNum=size(CrossGroupMeanDecodingResults{1},2);
ChRNLDiffSignificance=zeros(size(ChRNLDiff,2),size(ChRNLDiff,3));
for iTrainBin=1:TestBinNum
    for iTestBin = 1:TestBinNum
        tempBinDiff=ChRNLDiff(:,iTrainBin,iTestBin);
        The95ConfidenceInterval=prctile(tempBinDiff,[97.5,2.5]);
        if The95ConfidenceInterval(1)*The95ConfidenceInterval(2)>0%no cross with zero
            ChRNLDiffSignificance(iTrainBin,iTestBin)=1;
        end
    end
end
NpHRNLDiffSignificance=zeros(size(NpHRNLDiff,2),size(NpHRNLDiff,3));
for iTrainBin=1:TestBinNum
    for iTestBin = 1:TestBinNum
        tempBinDiff=NpHRNLDiff(:,iTrainBin,iTestBin);
        The95ConfidenceInterval=prctile(tempBinDiff,[97.5,2.5]);
        if The95ConfidenceInterval(1)*The95ConfidenceInterval(2)>0%no cross with zero
            NpHRNLDiffSignificance(iTrainBin,iTestBin)=1;
        end
    end
end
%%
MeanChRNLDiff=CrossGroupMeanDecodingResults{1}-CrossGroupMeanDecodingResults{2};
MeanNpHRNLDiff=CrossGroupMeanDecodingResults{3}-CrossGroupMeanDecodingResults{2};
DiffTCT=[{MeanChRNLDiff};{MeanNpHRNLDiff}];
DiffTCTIsSig=[{ChRNLDiffSignificance};{NpHRNLDiffSignificance}];

TimeBinNumber=size(MeanChRNLDiff,2);
ProceedingBinNum=bin_width/step_size;
X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
X=X+ProceedingBinNum*step_size/1000;

Marker=[{'ChR minus NL '};{'NpHR minus NL'}];
for i=1:length(DiffTCT)
    tempDiffTCT=DiffTCT{i};
    tempIsSig=DiffTCTIsSig{i};
    figure
    imagesc(X,X,tempDiffTCT*100,[-20 20]);
    hold on
    significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
    for iEvent = 1:length(significant_event_times)
        plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'), '--k','linewidth',1)
        plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)], '--k','linewidth',1)
    end
    PlotDiffIsSignificantMatrix=zeros(size(MeanChRNLDiff));
    PlotSigBinNum=length(find(X<=7));
    PlotDiffIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)=PlotDiffIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)+tempIsSig(1:PlotSigBinNum,1:PlotSigBinNum);
    contour(X,X,PlotDiffIsSignificantMatrix,[1 1],'-w','linewidth',1)
    axis xy
    colorbar('ytick',[-20 -10 0 10 20],'yticklabel',[-20 -10 0 10 20])
    %axis([-0.5 7.2 -0.5 7.2])
    set(gca,'xtick',[0 2 4 6], 'XTickLabel', [0 2 4 6],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6])
    xlabel('Test time (s)','fontsize',12)
    ylabel('Train time (s)','fontsize',12)
    title('Difference of decoding','fontsize',14)
    saveas(gcf,[GroupID '-' Marker{i} '- TCT Diff'],'fig')%
    saveas(gcf,[GroupID '-' Marker{i} '- TCT Diff'],'png')%
    close all
end
save(['DiffTCTWithBootstrapTest-' GroupID],'GroupID','CrossGroupDecodingResults','CrossGroupMeanDecodingResults','ChRNLDiff','NpHRNLDiff'...
    ,'MeanChRNLDiff','MeanNpHRNLDiff','ChRNLDiffSignificance','NpHRNLDiffSignificance','X','bin_width','step_size'...
    ,'OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','StartTime')