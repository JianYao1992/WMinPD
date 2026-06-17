%this code was used to compare difference(A-B) of NDT decoding
%CrossDayROCAna  AllUnitsOdorSelectivityAna PopulationHeatMap %PlotNDTDecodingResultsPermutationTest
%NDTPopulationDecoding  NDTDecodingAnaAccordingToPerformance TrialTypeAndLaserEffecsOnDecoding
%LaserEfeectsOnNDTDecodingAna TrialTypeAndLaserEffecsOnDecoding PlotDiffTCT
%PlotCQTCTDecoding CompareTwoTCTDiff
clear;clc;close all;

GroupID='AllNeu-CV-110';
DecodingTimes=1000;
ComparePeriod=[5 6];

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
    
%      AllDecodingFile=dir('*Decoding*.mat');%Parameters.mat
     AllDecodingFile=dir('*NDT*.mat');
    [RealCrossReSampleDecodingResults,RealDecodingResults,~,TimeBinNumber]=ConstruceNDTRealDecodingResults(AllDecodingFile,DecodingTimes);
    
    CrossGroupDecodingResults{iPath}=RealCrossReSampleDecodingResults;
    CrossGroupMeanDecodingResults{iPath}=RealDecodingResults;
    CrossGroupBinNum(1,iPath)=size(RealCrossReSampleDecodingResults,2);
end
AllParametersFile=dir('*All Parameters*.mat');
load(AllParametersFile.name)
cd(SplitPath{1})
MinBinNum=min(CrossGroupBinNum);
ProceedingBinNum=bin_width/step_size;
X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
X=X+ProceedingBinNum*step_size/1000;
X=X+step_size/1000/2;
X=X(1:MinBinNum);

if round(mean((CrossGroupBinNum)))~=mean(CrossGroupBinNum)
    MinBinNum=repmat({MinBinNum},size(CrossGroupDecodingResults));
    CrossGroupDecodingResults=cellfun(@(x,y) x(:,1:y),CrossGroupDecodingResults,MinBinNum,'uniformoutput',0);
    CrossGroupMeanDecodingResults=cellfun(@(x,y) x(:,1:y),CrossGroupMeanDecodingResults,MinBinNum,'uniformoutput',0);
end
%% calculate the difference of TCT decoding
TargetPeriodBinID=find(X>ComparePeriod(1)&X<ComparePeriod(2));
TargetPeriodBinID=repmat({TargetPeriodBinID},size(CrossGroupDecodingResults));
TargetPeriodMeanDecoding=cellfun(@(x,y) mean(x(:,y),2),CrossGroupDecodingResults,TargetPeriodBinID,'uniformoutput',0);

ChRNLDiff=TargetPeriodMeanDecoding{1}-TargetPeriodMeanDecoding{2};
NpHRNLDiff=TargetPeriodMeanDecoding{3}-TargetPeriodMeanDecoding{2};

ChRNLDiff95CI=prctile(ChRNLDiff,[97.5,2.5 75 25]);
NpHRNLDiff95CI=prctile(NpHRNLDiff,[97.5,2.5 75 25]);
MedianChRNLDiff=median(ChRNLDiff);
MedianNpHRNLDiff=median(NpHRNLDiff);

IsSigDiff=zeros(1,2);
if ChRNLDiff95CI(1)*ChRNLDiff95CI(2)>0
    IsSigDiff(1)=1;
end
if NpHRNLDiff95CI(1)*NpHRNLDiff95CI(2)>0
    IsSigDiff(2)=1;
end

ChRNLDiffDecoding=[MedianChRNLDiff ChRNLDiff95CI];
NpHRNLDiffDecoding=[MedianNpHRNLDiff NpHRNLDiff95CI];

Marker=[{'ChR minus NL '};{'NpHR minus NL'}];
figure
BoxPlot(ChRNLDiffDecoding*100,0.8,[0 0 1])
hold on
BoxPlot(NpHRNLDiffDecoding*100,1.2,[0 0.5 0])
xlim([0.5 1.5])
plot([0 2],[0 0],'--k')
set(gca,'xtick',[0.8 1.2],'xticklabel',Marker)
title('Difference of decoding (%)','fontsize',14)
saveas(gcf,[GroupID '- Diff Decoding'],'fig')%
saveas(gcf,[GroupID '- Diff Decoding'],'png')%
close all
save(['DiffDecodingWithBootstrapTest-' GroupID],'GroupID','ChRNLDiffDecoding','NpHRNLDiffDecoding','ChRNLDiff','NpHRNLDiff','IsSigDiff'...
    ,'X','bin_width','step_size','OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','StartTime')