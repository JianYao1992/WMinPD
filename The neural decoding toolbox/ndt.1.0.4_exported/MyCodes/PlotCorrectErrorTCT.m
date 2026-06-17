%this code was used to compare the correct/Error trials TCT decoding results
clear;clc;close all
DecodingTimes=50;
ShuffleDecodingTimes=1000;

ColorBarRange=[40 85];
CurrentPath=pwd;
AllPath=dir;
myDir = find(vertcat(AllPath.isdir));
AllPath=struct2cell(AllPath);
AllPath=AllPath(1,myDir(3:end));
AllPath=AllPath';
CrossGroupCorrErrTCT=cell(size(AllPath,1),2);
CrossGroupIsSig=cell(size(AllPath,1),2);
for iPath=1:length(AllPath)%go through each directory
    Path=[CurrentPath '\' AllPath{iPath,1}];
    cd(Path);
    
    GroupID=AllPath{iPath,1};
    SubPath=dir;
    if size(SubPath,1)>0
        SubPath=struct2cell(SubPath);
        SubPath=SubPath(1,3:end);
        
        TrialType=[{'CorrectTrials'};{'ErrorTrials'}];
        CorrErrTCT=cell(1,2);
        CorrErrIsSig=cell(1,2);
        CorrErrShuffleTCTDecodingNullDistribution=cell(1,2);
        figure('position',[250 200 1000,450])
        for i=1:length(SubPath)
            cd([Path '\' SubPath{i}])
            if exist('Shuffle','dir')==7
                ShuffleDecodingDir='Shuffle';
            else
                ShuffleDecodingDir=[];
            end
            
            AllDecodingFile=dir('*NDT*.mat');%Parameters.mat
            [RealCrossReSampleDecodingResults,RealDecodingResults,RealTCTDecodingStd,TimeBinNumber]...
                =ConstruceRealDecodingResults(AllDecodingFile,DecodingTimes);
            CorrErrTCT{i}=RealDecodingResults;
            
            ShuffleTCTDecodingNullDistribution=zeros(ShuffleDecodingTimes,TimeBinNumber,TimeBinNumber);
            StartBin=1;%
            EndBin=TimeBinNumber;% 1 second after test odor offset
            TestBinNum=EndBin-StartBin+1;
            ClusterBasedPermuTestIsSignificant=zeros(TestBinNum,TestBinNum);
            ShuffleIsSignificant=zeros(ShuffleDecodingTimes,TestBinNum,TestBinNum);
            ShuffleSigClusterSize=zeros(TestBinNum,ShuffleDecodingTimes);
            RealDecodingResultsSigClusterSize=cell(TestBinNum,1);
            RealDecodingResultsSigClusterID=cell(TestBinNum,1);
            if ~isempty(ShuffleDecodingDir)
                ShuffleTCTDecodingNullDistribution=ConstructShuffleTCTDecoding(ShuffleDecodingDir...
                    ,ShuffleDecodingTimes,TimeBinNumber,step_size,StartTime);
                %% create significant bin index from the null_distribution at each time point based on cluster-based permutation test
                [IsSignificant,ClusterBasedPermuTestIsSignificant,ShuffleIsSignificant,ShuffleSigClusterSize...
                    ,RealDecodingResultsSigClusterSize,RealDecodingResultsSigClusterID]=TCTClusterBasedPermutationTest(RealDecodingResults...
                    ,ShuffleTCTDecodingNullDistribution,TestBinNum,ShuffleDecodingTimes);
            end
            CorrErrShuffleTCTDecodingNullDistribution{i}=ShuffleTCTDecodingNullDistribution;
            CorrErrIsSig{i}=ClusterBasedPermuTestIsSignificant;
            
            AllParametersDecodingFile=dir('*Parameters*.mat');%
            load(AllParametersDecodingFile.name)
            ProceedingBinNum=bin_width/step_size;
            X=-(4-StartTime):step_size/1000:(TimeBinNumber*step_size/1000-(4-StartTime))-step_size/1000;
            X=X+ProceedingBinNum*step_size/1000+step_size/1000/2;
            
            subplot('position',[0.08+(i-1)*0.43,0.09,0.38+(i-1)*0.04,0.78]);%[left bottom width height]
            imagesc(X,X,RealDecodingResults*100,[45 85]);
            hold on
            % extract and plot the boundary (X axis) of significant decoding in each training time line(Y axis)
            AllIsSignificantMatrix=zeros(size(RealDecodingResults));
            PlotSigBinNum=length(find(X<=7.5));
            if ~isempty(ShuffleDecodingDir)
                if IsClusterBasedPermationTest==1
                    AllIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)=AllIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)+ClusterBasedPermuTestIsSignificant(1:PlotSigBinNum,1:PlotSigBinNum);
                else
                    AllIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)=AllIsSignificantMatrix(1:PlotSigBinNum,1:PlotSigBinNum)+IsSignificant(1:PlotSigBinNum,1:PlotSigBinNum);
                end
                contour(X,X,AllIsSignificantMatrix,[1 1],'-w','linewidth',1)
            end
            significant_event_times=[0 OdorMN OdorMN+DelayMN 2*OdorMN+DelayMN 2*OdorMN+DelayMN+ResponseMN 2*OdorMN+DelayMN+ResponseMN+WaterMN];
            for iEvent = 1:length(significant_event_times)
                plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'), '--k','linewidth',1)
                plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)], '--k','linewidth',1)
            end
            colorbar('ytick',[0 10 20 30 40 50 60 70 80],'yticklabel',[0 10 20 30 40 50 60 70 80])
            set(gca,'xtick',[0 2 4 6], 'XTickLabel', [0 2 4 6],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6]);%add by CQ
            axis([-0.5 7.2 -0.5 7.2])
            xlabel('Test time (s)','fontsize',12)
            ylabel('Train time (s)','fontsize',12)
            axis xy
            title([GroupID '-' TrialType{i}])
        end
        cd(CurrentPath)
        saveas(gcf,[TitleName '-' TrialType{i}],'fig')%
        saveas(gcf,[TitleName '-' TrialType{i}],'png')%
        close all
        CrossGroupCorrErrTCT(iPath,:)=CorrErrTCT;
        CrossGroupIsSig(iPath,:)=CorrErrIsSig;
        %% plot the difference of TCT decoding between correct and error trials
        DiffTCT=CrossGroupCorrErrTCT{iPath,1}-CrossGroupCorrErrTCT{iPath,2};
        imagesc(X,X,DiffTCT*100,[-20 20]);
        hold on
        for iEvent = 1:length(significant_event_times)
            %     line([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'), 'color', [0 0 0])
            %     line(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)], 'color', [0 0 0])
            plot([significant_event_times(iEvent), significant_event_times(iEvent)], get(gca, 'YLim'),'--k','linewidth',1)
            plot(get(gca, 'XLim'), [significant_event_times(iEvent), significant_event_times(iEvent)],'--k','linewidth',1)
        end
        axis xy
        axis([-0.5 7.2 -0.5 7.2])
        set(gca,'xtick',[0 2 4 6], 'XTickLabel', [],'ytick',[0 2 4 6], 'yTickLabel', [0 2 4 6]);
        saveas(gcf,['CorrErrDiffTCT-' GroupID],'fig')%
        saveas(gcf,['CorrErrDiffTCT-' GroupID],'png')%
        close all        
    end
    save(['CorrectErrTCTWithPermuTest-' GroupID],'TitleName','CorrErrTCT','CorrErrIsSig','X','bin_width'...
        ,'step_size','ShuffleDecodingTimes','OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','StartTime','GroupID')
end
cd(CurrentPath)
%% plot ChR-NL-NpHP diff-TCT in correct/error trials
CorrTrialChRNLDiffTCT=CrossGroupCorrErrTCT{1,1}-CrossGroupCorrErrTCT{2,1};
CorrTrialNpHRNLDiffTCT=CrossGroupCorrErrTCT{3,1}-CrossGroupCorrErrTCT{2,1};
ErrorTrialChRNLDiffTCT=CrossGroupCorrErrTCT{1,2}-CrossGroupCorrErrTCT{2,2};
ErrorTrialNpHRNLDiffTCT=CrossGroupCorrErrTCT{3,2}-CrossGroupCorrErrTCT{2,2};

figure('position',[350 100 1000,800])
subplot('position',[0.08,0.51,0.38,0.38])
HeatPlotTCT(CorrTrialChRNLDiffTCT,X,[-20 20],OdorMN,DelayMN,ResponseMN,WaterMN,'Corr Trial ChR-NL Diff TCT')
subplot('position',[0.51,0.51,0.38,0.38])
HeatPlotTCT(CorrTrialNpHRNLDiffTCT,X,[-20 20],OdorMN,DelayMN,ResponseMN,WaterMN,'Corr Trial NpHR-NL Diff TCT')
subplot('position',[0.08,0.08,0.38,0.38])
HeatPlotTCT(ErrorTrialChRNLDiffTCT,X,[-20 20],OdorMN,DelayMN,ResponseMN,WaterMN,'Error Trial ChR-NL Diff TCT')
subplot('position',[0.51,0.08,0.38,0.38])
HeatPlotTCT(ErrorTrialNpHRNLDiffTCT,X,[-20 20],OdorMN,DelayMN,ResponseMN,WaterMN,'Error Trial NpHR-NL Diff TCT')
saveas(gcf,'TrialTypeLaserEffectOnDiffTCT','fig')%
saveas(gcf,'TrialTypeLaserEffectOnDiffTCT','png')%
close all
%%
save('CrossGroupCorrectErrTCTAna','CrossGroupCorrErrTCT','CrossGroupIsSig','X','bin_width','step_size'...
    ,'ShuffleDecodingTimes','OdorMN','DelayMN','ResponseMN','WaterMN','ITIMN','StartTime','GroupID')