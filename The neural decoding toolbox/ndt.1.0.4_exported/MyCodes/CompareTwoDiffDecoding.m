%this code was used to compare difference(A-B) of NDT decoding
%CrossDayROCAna  AllUnitsOdorSelectivityAna PopulationHeatMap %PlotNDTDecodingResultsPermutationTest
%NDTPopulationDecoding  NDTDecodingAnaAccordingToPerformance TrialTypeAndLaserEffecsOnDecoding
%LaserEfeectsOnNDTDecodingAna TrialTypeAndLaserEffecsOnDecoding PlotDiffTCT
%PlotCQTCTDecoding CompareTwoTCTDiff
clear;clc;close all;
GroupID='NL';
DecodingTimes=1000;
ComparePeriod=[4.5 5.5];
PeriodMarker=[];
for i=1:length(ComparePeriod)    
    PeriodMarker=[PeriodMarker '-' num2str(ComparePeriod(i))];
end
PeriodMarker=strrep(PeriodMarker,'.','_');

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

CorrErrorDiff=TargetPeriodMeanDecoding{1}-TargetPeriodMeanDecoding{2};

CorrErrorDiff95CI=prctile(CorrErrorDiff,[97.5,2.5 75 25]);
MedianCorrErrorDiff=median(CorrErrorDiff);
CorrectErrorDiffDecoding=[MedianCorrErrorDiff CorrErrorDiff95CI];
IsSigDiff=0;
if CorrErrorDiff95CI(1)*CorrErrorDiff95CI(2)>0
    IsSigDiff=1;
end

Marker={'Correct minus Error '};
figure
BoxPlot(CorrectErrorDiffDecoding*100,1,[0 0 1])
hold on
xlim([0.5 1.5])
plot([0 2],[0 0],'--k')
set(gca,'xtick',1,'xticklabel',Marker)
title(['Difference of decoding between Correct and Error trials' PeriodMarker],'fontsize',14)
saveas(gcf,[GroupID '-Correct and Error trials Diff Decoding' PeriodMarker],'fig')%
saveas(gcf,[GroupID '-Correct and Error trials Diff Decoding' PeriodMarker],'png')%
close all
save(['DiffDecodingWithBootstrapTest-' GroupID PeriodMarker],'GroupID','CorrectErrorDiffDecoding','CorrErrorDiff'...
    ,'IsSigDiff','X','bin_width','step_size','OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','StartTime','ComparePeriod')