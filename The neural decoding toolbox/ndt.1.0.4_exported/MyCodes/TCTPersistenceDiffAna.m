%this code was used to analize the difference of TCT Decoding persistence
%between ChR-activation, control and NpHR-suppression groups
clear;clc;close all
NeuGroupMarker=[{'AllNeurons-450'};{'TransientNeu-20-ExcAllRevNeu'};{'SustainedNeu-20_ExcAllRevNeu'};{'Switched neurons-20'}];
TestPeriod=[0 7];
TestPeriodMarker=num2str(TestPeriod);
TestPeriodMarker=strrep(TestPeriodMarker,'  ','-');

CurrentPath=pwd;
AllPath=genpath(CurrentPath);
SplitPath=strsplit(AllPath,';');
SubPath=SplitPath';
SubPath=SubPath(2:end-1);
SubPath=ExcludeShuffleDir(SubPath);

NewTCTPath=cell(size(SubPath,1),1);
for i=1:length(NeuGroupMarker)
    tempNeuGroup=NeuGroupMarker{i};
    T = regexpi(SubPath, tempNeuGroup);
    E = ~cellfun(@isempty, T);
    NewTCTPath{i}=cell2mat(SubPath(E));
end

DiffNeuGroupDiffTCTPersistence=cell(2,size(NewTCTPath,1));
CrossGroupSignificantBinNum=cell(1,size(NewTCTPath,1));
for iPath=1:size(NewTCTPath,1)%go through each directory
    Path=NewTCTPath{iPath,1};
    cd(Path);    
    AllTCTDecodingFile=dir('*CrossTemporalDecodingWithPermuTest*.mat');%Parameters.mat
    if size(AllTCTDecodingFile,1)>0
        load(AllTCTDecodingFile(1).name,'X')
        StartBin=find(X>=TestPeriod(1),1);
        EndBin=find(X<=TestPeriod(2), 1, 'last' );
        %EndBin=EndBin-1;
        PlotSigBinRange=StartBin:EndBin;
        SignificantBinNum=zeros(size(AllTCTDecodingFile,1),EndBin-StartBin+1);
        for i=1:size(AllTCTDecodingFile,1)%go through ChR/NL/NpHR groups
            load(AllTCTDecodingFile(i).name)
            for iTrainBin=StartBin:EndBin
                SignificantBinNum(i,iTrainBin-StartBin+1)=length(find(ClusterBasedPermuTestIsSignificant(iTrainBin,PlotSigBinRange)==1));
            end
        end
        SignificantBinNum=SignificantBinNum*step_size/1000;
        %% calculate the difference of TCT decoding persistence
        ChRNLPersistenceDiff=SignificantBinNum(1,:)-SignificantBinNum(2,:);
        NpHRNLPersistenceDiff=SignificantBinNum(3,:)-SignificantBinNum(2,:);
        
        DiffNeuGroupDiffTCTPersistence(:,iPath)=[{ChRNLPersistenceDiff};{NpHRNLPersistenceDiff}];
        CrossGroupSignificantBinNum{iPath}=SignificantBinNum;
    end
end
cd(SplitPath{1})
%% plot the difference of the persistence of TCT-Decoding results for different neuron groups
Colors = [[0 0 0];[0 0.5 0];[1 0 0];[0 0 1]];%;[1 0.5 0.5];[1 0 0]
NeuMarkers=[{'AllNeu'};{'TransientNeu'};{'SustainedNeu'};{'SwitchedNeu'}];
GroupMarker=[{'ChR minus Control'};{'NpHR minus Control'}];
for j=1:2%go through ChR and NpHR group
    figure
    Max=zeros(1,size(DiffNeuGroupDiffTCTPersistence,2));
    Min=zeros(1,size(DiffNeuGroupDiffTCTPersistence,2));
    for i=1:size(DiffNeuGroupDiffTCTPersistence,2)
        plot(X(StartBin:EndBin),DiffNeuGroupDiffTCTPersistence{j,i},'-','color',Colors(i,:),'linewidth',1)
        hold on
        Max(i)=max(DiffNeuGroupDiffTCTPersistence{j,i});
        Min(i)=min(DiffNeuGroupDiffTCTPersistence{j,i});
    end
    plot([-0.5 7.5],[0 0],'--k')
    AddLegend(NeuMarkers,Colors)
    EventCurve(OdorMN,DelayMN,ResponseMN,WaterMN,max(Max),min(Min))
    xlim([-0.5 7.5])
    ylim([min(Min)*1.05 max(Max)*1.05])
    xlabel('Train time(s)','fontsize',12)
    ylabel('Diff of persistence of TCT decoding (s)','fontsize',12)
    title(['Diff of the persistence of TCT decoding for different neu groups-' GroupMarker{j} '-' TestPeriodMarker])
    saveas(gcf,['Diff of the persistence of TCT decoding for different neu groups-' GroupMarker{j} '-' TestPeriodMarker],'fig')
    saveas(gcf,['Diff of the persistence of TCT decoding for different neu groups-' GroupMarker{j} '-' TestPeriodMarker],'png')
    close all
end
%% 
% Colors=[[19 130 197]/255;[0 0 0];[19 156 78]/255];
% Colors=[[0 0 0];[0.14 0.14 0.14];[0.28 0.28 0.28];[0.42 0.42 0.42];[0.56 0.56 0.56];[0.7 0.7 0.7];[0.84 0.84 0.84]];
Colors=[[0 0 1];[0 0 0];[0.2 0.2 0.2];[0.4 0.4 0.4];[0.6 0.6 0.6];[0.8 0.8 0.8];[1 0 1]];%
% Colors=[[0 0 0];[0.2 0.2 0.2];[0.4 0.4 0.4];[0.6 0.6 0.6];[0.8 0.8 0.8]];
Legends=[{'Sample'};{'Delay1'};{'Delay2'};{'Delay3'};{'Delay4'};{'Delay5'};{'Test'}];% 
%plot ChR VS. NL group significant TCT decoding duration
for i=1:size(CrossGroupSignificantBinNum,2)    
    ChRSignificantBinNum=CrossGroupSignificantBinNum{i}(1,:);
    NLSignificantBinNum=CrossGroupSignificantBinNum{i}(2,:);
    
    ChR95Percentile=prctile(ChRSignificantBinNum,[97.5 2.5]);
    NL95Percentile=prctile(NLSignificantBinNum,[97.5 2.5]);
            
    [p,h] = signrank(ChRSignificantBinNum,NLSignificantBinNum);   
    AddLegend(Legends,Colors)
    hold on
    BlockNum=ceil(length(ChRSignificantBinNum)/10);
    for j=1:BlockNum
        scatter(NLSignificantBinNum((j-1)*10+1:j*10),ChRSignificantBinNum((j-1)*10+1:j*10),[],Colors(j,:),'Marker','.','markerfacecolor',Colors(j,:))        
    end
    plot([0 TestPeriod(2)],[0 TestPeriod(2)],'--k')
    text(0.2,TestPeriod(2)-0.2,['p=' num2str(p)])
    text(0.2,TestPeriod(2)-0.5,['n=' num2str(length(ChRSignificantBinNum))])
    axis([0 TestPeriod(2) 0 TestPeriod(2)])
    title(['The duration of TCT decoding-ChR-NL-' NeuMarkers{i} '-' TestPeriodMarker])
    saveas(gcf,['The duration of TCT decoding-ChR-NL-' NeuMarkers{i} '-' TestPeriodMarker],'fig')
    saveas(gcf,['The duration of TCT decoding-ChR-NL-' NeuMarkers{i} '-' TestPeriodMarker],'png')
    ResizeFigureForPaper(['The duration of TCT decoding-ChR-NL-' NeuMarkers{i} '-' TestPeriodMarker],...
        [0.85 0.85],[TestPeriod TestPeriod],0,[0 2 4 6 8],[0 2 4 6 8])
    close all
end
%% plot NpHR VS. NL group significant TCT decoding duration
for i=1:size(CrossGroupSignificantBinNum,2)    
    NpHRSignificantBinNum=CrossGroupSignificantBinNum{i}(3,:);
    NLSignificantBinNum=CrossGroupSignificantBinNum{i}(2,:);
    
    NpHR95Percentile=prctile(NpHRSignificantBinNum,[97.5 2.5]);
    NL95Percentile=prctile(NLSignificantBinNum,[97.5 2.5]);
            
    [p1,h1] = signrank(NpHRSignificantBinNum,NLSignificantBinNum);    
    AddLegend(Legends,Colors)
    hold on
    BlockNum=ceil(length(NpHRSignificantBinNum)/10);
    for j=1:BlockNum
        scatter(NLSignificantBinNum((j-1)*10+1:j*10),NpHRSignificantBinNum((j-1)*10+1:j*10),[],Colors(j,:),'Marker','.','markerfacecolor',Colors(j,:))
    end
    hold on
    plot([0 TestPeriod(2)],[0 TestPeriod(2)],'--k')
    text(0.2,TestPeriod(2)-0.2,['p=' num2str(p1)])
    text(0.2,TestPeriod(2)-0.5,['n=' num2str(length(NpHRSignificantBinNum))])
    axis([0 TestPeriod(2) 0 TestPeriod(2)])
    title(['The duration of TCT decoding-NpHR-NL-' NeuMarkers{i} '-' TestPeriodMarker])
    saveas(gcf,['The duration of TCT decoding-NpHR-NL-' NeuMarkers{i} '-' TestPeriodMarker],'fig')
    saveas(gcf,['The duration of TCT decoding-NpHR-NL-' NeuMarkers{i} '-' TestPeriodMarker],'png')
    ResizeFigureForPaper(['The duration of TCT decoding-NpHR-NL-' NeuMarkers{i} '-' TestPeriodMarker],...
        [0.85 0.85],[TestPeriod TestPeriod],0,[0 2 4 6 8],[0 2 4 6 8])
    close all
end
%% plot the averaged diff-TCT decoding results
MeanDiff=cellfun(@mean,DiffNeuGroupDiffTCTPersistence,'uniformoutput',0);
MeanDiff=cell2mat(MeanDiff);
STD=cellfun(@std,DiffNeuGroupDiffTCTPersistence,'uniformoutput',0);
Length=cellfun(@length,DiffNeuGroupDiffTCTPersistence,'uniformoutput',0);
SEM=cell2mat(cellfun(@(x,y) x/(y^0.5),STD,Length,'uniformoutput',0));

figure
bar(1:size(MeanDiff,2),MeanDiff(1,:),'facecolor','none','edgecolor',[0 0 0])
hold on
errorbar(1:size(MeanDiff,2),MeanDiff(1,:),SEM(1,:),'linestyle','none','color',[0 0 0])
ylabel('Mean duration of TCT decoding (s)','fontsize',12)
box off
set(gca,'xtick',1:size(MeanDiff,2),'xticklabel',NeuMarkers)
saveas(gcf,['The mean duration of TCT decoding-ChR-NL-' TestPeriodMarker],'fig')
saveas(gcf,['The mean duration of TCT decoding-ChR-NL-' TestPeriodMarker],'png')
ResizeFigureForPaper(['The mean duration of TCT decoding-ChR-NL-' TestPeriodMarker],[1.44 0.6],[0.2 4.7 -1.2 0.6],0,[1 2 3 4],[-1.2 -0.6 0 0.6])
close all

figure
bar(1:size(MeanDiff,2),MeanDiff(2,:),'facecolor','none','edgecolor',[0 0 0])
hold on
errorbar(1:size(MeanDiff,2),MeanDiff(2,:),SEM(2,:),'linestyle','none','color',[0 0 0])
ylabel('Mean duration of TCT decoding (s)','fontsize',12)
box off
set(gca,'xtick',1:size(MeanDiff,2),'xticklabel',NeuMarkers)
saveas(gcf,['The mean duration of TCT decoding-NpHR-NL-' TestPeriodMarker],'fig')
saveas(gcf,['The mean duration of TCT decoding-NpHR-NL-' TestPeriodMarker],'png')
ResizeFigureForPaper(['The mean duration of TCT decoding-NpHR-NL-' TestPeriodMarker],[1.44 0.6],[0.2 4.7 -2 0.5],0,[1 2 3 4],[-2 -1.5 -1 -0.5 0 0.5])
close all