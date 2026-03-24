%% Behavioral performance analysis for population of mice
% support two analysis modes: 'Distinct sessions or windows' and 'Phase'

clear; clc; close all;

%% Core parameter configuration
AnalysisStyle = 'Separation';  % optional：'Seperation' or 'Integration'
% if AnalysisStyle is 'Seperation'
GroupName = {'Monomer injection','PFF injection','PFF injection activation'};  % adjust groups as needed
filesavepath = 'D:\Data\CombinedAnalysis\Training';  % path to save results
IsPseudoDelay = 0;
BeforeTrial = 4; SampOdorLen = 1; DelayLen = [10; 20]; TestOdorLen = 1;
TestRespInterval = 0; RespWindowLen = 1; TimeGain = 10; LickEfficiencyWindowLen = 0.3;
ColorSet = {[0 0 0],[222 137 44]/255,[67 106 178]/255};  % group colors
LineWidth = 2;
LineStyle = '-';
MarkerShape = 'o';
MarkerSize = 10;
TickLabelSize = 16;
AxisLabelSize = 16;

% mode-specific parameters
if strcmp(AnalysisStyle, 'Integration')
    TimesID = [1 2 3 4 5 6];  % range of time points for analysis
    % phase name configuration
    if IsPseudoDelay == 0
        phase = sprintf('Learning day %d-%d',TimesID(1),TimesID(end));
        Category = 'Session';
    else
        phase = sprintf('Learning window %d-%d',TimesID(1),TimesID(end));
        Category = 'Window';
    end
elseif strcmp(AnalysisStyle, 'Separation')
    phase = 'Learning phase';  % can be changed to 'Trained phase'
    TimesNum = 6;  % number of learning days
    TrialLaserType = 'laser on';  % laser condition
    Category = 'Session';

    % X-axis name configuration
    if strcmp(phase,'Learning phase')
        XaxisName = 'Learning day';
    else
        XaxisName = 'Welltrained';
    end
    % pseudo-delay related parameters
    if IsPseudoDelay == 1
        Category = 'Window';
        TotalTrialNum = 192;
        MaxWindowNumInSess = 8;
        TrialNuminWindow = TotalTrialNum/(numel(DelayLen)*MaxWindowNumInSess);
    end
end

%% Load data
filename = cell(1,numel(GroupName));
Dataofmice = cell(1,numel(GroupName));
for iGroup = 1:numel(GroupName)
    [filename{iGroup},~] = uigetfile({'*.mat','Matlab files(*.mat)';},'Pick some files','MultiSelect','on');
    Dataofmice{iGroup} = cell(size(filename{iGroup},2),1);
    for iMouse = 1:size(filename{iGroup},2)
        Dataofmice{iGroup}{iMouse} = load(filename{iGroup}{iMouse});
    end
end

%% Data processing——select different processing functions based on analysis mode
AllSessionMiceBehavior = cell(1,numel(GroupName));
for iGroup = 1:numel(GroupName)
    % calculate licking efficiency analysis window
    LickEffAnaWind = cell(numel(filename{iGroup}),numel(DelayLen));
    for iMouse = 1:numel(filename{iGroup})
        for iDelay = 1:numel(DelayLen)
            LickEffAnaWind{iMouse,iDelay} = horzcat(...
                BeforeTrial+SampOdorLen+DelayLen(iDelay)+TestOdorLen+TestRespInterval, ...
                BeforeTrial+SampOdorLen+DelayLen(iDelay)+TestOdorLen+TestRespInterval+LickEfficiencyWindowLen);
        end
    end

    % call the corresponding data summary function
    AllSessionMiceBehavior{iGroup} = SummarizeAllPerfandLick(Dataofmice{iGroup},AnalysisStyle,TimesID,TimesNum,LickEffAnaWind,TrialNuminWindow,DelayLen,TimeGain,Category);
end

%% Result visualization and statistical analysis
if strcmp(AnalysisStyle, 'Separation')
    % Plot hit and CR rates
    for iDelay = 1:numel(DelayLen)
        figure('Position',[219 303 750 600]);
        CompareDiffGroupsTimeLapsedBehavior(phase, 'Hit', ['delay' num2str(iDelay)], AllSessionMiceBehavior, ...
            ColorSet, LineWidth, LineStyle, MarkerShape, ColorSet, ColorSet, MarkerSize, filesavepath);
        CompareDiffGroupsTimeLapsedBehavior(phase, 'CR', ['delay' num2str(iDelay)], AllSessionMiceBehavior, ...
            ColorSet, LineWidth, LineStyle, MarkerShape, ColorSet, ColorSet, MarkerSize, filesavepath);
        legend(GroupName,'Location','southeast');
        legend('boxoff');
        % Set the coordinate axes
        SetXYaxisProperty(1,1,TimesNum,0.5,TimesNum+0.5,XaxisName,0,20,100,0,100,'Hit and CR rates (%)',TickLabelSize,AxisLabelSize);
        box off;
        set(gcf, 'Renderer', 'Painter');
        saveas(gcf,fullfile(filesavepath,sprintf('Hit and CR rates comparison-delay%d-%s',iDelay,phase)),'fig');
        close;
    end

    % Plot licking efficiencies
    for iDelay = 1:numel(DelayLen)
        figure('Position',[219 303 750 600]);
        CompareDiffGroupsTimeLapsedBehavior(phase, 'LickEfficiency', ['delay' num2str(iDelay)], AllSessionMiceBehavior, ...
            ColorSet, LineWidth, LineStyle, MarkerShape, ColorSet, ColorSet, MarkerSize, filesavepath);
        legend(GroupName,'Location','southeast');
        legend('boxoff');
        % Set the coordinate axes
        SetXYaxisProperty(1,1,TimesNum,0.5,TimesNum+0.5,XaxisName,0,20,100,0,100,'Licking efficiency (%)',TickLabelSize,AxisLabelSize);
        box off;
        set(gcf, 'Renderer', 'Painter');
        saveas(gcf,fullfile(filesavepath,sprintf('Lick efficiency comparison-delay%d-%s',iDelay,phase)),'fig');
        close;
    end

    % Plot Dprime
    if iLickEff == 1
        for iDelay = 1:numel(DelayLen)
            figure('Position',[219 303 750 600]);
            CompareDiffGroupsTimeLapsedBehavior(phase, 'Dprime', ['delay' num2str(iDelay)], AllSessionMiceBehavior, ...
                ColorSet, LineWidth, LineStyle, MarkerShape, ColorSet, ColorSet, MarkerSize, filesavepath);            legend(GroupName,'Location','southeast');
            legend('boxoff');
            % Set the coordinate axes
            SetXYaxisProperty(1,1,TimesNum,0.5,TimesNum+0.5,XaxisName,0,20,100,0,100,'Performance (d")',TickLabelSize,AxisLabelSize);
            box off;
            set(gcf, 'Renderer', 'Painter');
            saveas(gcf,fullfile(filesavepath,sprintf('Dprime comparison-delay%d-%s',iDelay,phase)),'fig');
            close;
        end
    end

    % Plot the licking rate of hit trials
    for iDay = 1:TimesNum
        for iDelay = 1:numel(DelayLen)
            figure('Position',[219 303 750 600]);
            for iGroup = 1:numel(AllSessionMiceBehavior)
                plotshadow(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},ColorSet{iGroup},2,3,-0.05-BeforeTrial,TimeGain);
            end
            % Cluster-based permutation test
            if numel(GroupName) == 3
                [tempSigTime_group1,tempSigTime_group2] = ClusterBasedPermutationTest_ForBothReal(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},AllSessionMiceBehavior{2}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay});
                LabelSignificantPositions(tempSigTime_group1-BeforeTrial*TimeGain,10,5,ColorSet{2});
                LabelSignificantPositions(tempSigTime_group2-BeforeTrial*TimeGain,10,5,ColorSet{2});
                [tempSigTime_group3,tempSigTime_group2] = ClusterBasedPermutationTest_ForBothReal(AllSessionMiceBehavior{3}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},AllSessionMiceBehavior{2}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay});
                LabelSignificantPositions(tempSigTime_group3-BeforeTrial*TimeGain,10,5,ColorSet{3});
                LabelSignificantPositions(tempSigTime_group2-BeforeTrial*TimeGain,10,5,ColorSet{3});
            elseif numel(GroupName) == 2
                [tempSigTime_group1,tempSigTime_group2] = ClusterBasedPermutationTest_ForBothReal(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},AllSessionMiceBehavior{2}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay});
                LabelSignificantPositions(tempSigTime_group1-BeforeTrial*TimeGain,10,5,ColorSet{2});
                LabelSignificantPositions(tempSigTime_group2-BeforeTrial*TimeGain,10,5,ColorSet{2});
            end
            % Plot event curve
            PlotEventCurve(0,SampOdorLen,DelayLen(iDelay),TestOdorLen,RespWindowLen,2,8);
            SetXYaxisProperty(-1*BeforeTrial,1,size(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},2)/TimeGain-BeforeTrial,-0.3,size(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},2)/TimeGain-BeforeTrial,'Time from sample onset (s)',...
                0,2,8,0,8,'Lick rate (Hz)',TickLabelSize,AxisLabelSize);
            box off;
            set(gcf, 'Renderer', 'Painter');
            saveas(gcf,fullfile(filesavepath,sprintf('Lick rate comparison in hit trials-delay%d trials-day %d-%s',iDelay,iDay,phase)),'fig');
            close;
        end
    end

    if strcmp(AnalysisStyle, 'Integration')
        for iDelay = 1:numel(DelayLen)
            % performance
            figure('Position',[219 303 600 900]);
            for iGroup = 1:numel(GroupName)
                plotBarAndError(ColorSet{iGroup},1.1+0.8*(iGroup-1),AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).Perf,1);
                arrayfun(@(x) plot(1.1+0.8*(iGroup-1)+rand()*0.6-0.3,AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).Perf(x,1),'o','MarkerSize',6,'MarkerFaceColor',ColorSet{iGroup},'MarkerEdgeColor','none'),1:numel(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).Perf));
            end
            % statistical test
            if numel(GroupName) == 2
                Pvalue_Perf = ranksum(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).Perf,AllSessionMiceBehavior{2}.(['delay' num2str(iDelay)]).Perf);
            elseif numel(GroupName) > 2
                Perf = []; GroupID = [];
                for iGroup = 1:numel(GroupName)
                    Perf = [Perf; AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).Perf];
                    GroupID = [GroupID; iGroup*ones(numel(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).Perf),1)];
                end    
                [Pvalue_Perf,tbl_Perf,stats_Perf] = anova1(Perf,GroupID,'off');
                [Pvalue_Pairwise_Perf,~,~,~] = multcompare(stats_Perf,'CriticalValueType','lsd');
                save(fullfile(filesavepath,sprintf('Pvalue for Performance comparison_delay%d_%s.mat',iDelay,phase)),'tbl_Perf','stats_Perf','Pvalue_Pairwise_Perf','-v7.3');
            end
            SetXYaxisProperty([],1,[],0.6,1.6+0.8*(numel(GroupName)-1),'Group',0,20,100,0,100,'Rates (%)',12,12);
            title(sprintf('p = %d',Pvalue_Perf));
            box off;
            set(gcf, 'Renderer', 'Painter');
            saveas(gcf,fullfile(filesavepath,sprintf('Performance comparison-delay%d-%s',iDelay,phase)),'fig');
            close;

            % hit rate
            figure('Position',[219 303 600 900]);
            for iGroup = 1:numel(GroupName)
                plotBarAndError(ColorSet{iGroup},1.1+0.8*(iGroup-1),AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).HitRate,1);
                arrayfun(@(x) plot(1.1+0.8*(iGroup-2)+rand()*0.6-0.3,AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).HitRate(x,1),'o','MarkerSize',6,'MarkerFaceColor',ColorSet{iGroup},'MarkerEdgeColor','none'),1:numel(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).HitRate));
            end
            if numel(GroupName) == 2
                Pvalue_HitRate = ranksum(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).HitRate,AllSessionMiceBehavior{2}.(['delay' num2str(iDelay)]).HitRate);
            elseif numel(GroupName) > 2
                HitRate = []; GroupID = [];
                for iGroup = 1:numel(GroupName)
                    HitRate = [HitRate; AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).HitRate];
                    GroupID = [GroupID; iGroup*ones(numel(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).HitRate),1)];
                end
                [Pvalue_HitRate,tbl_HitRate,stats_HitRate] = anova1(HitRate,GroupID,'off');
                [Pvalue_Pairwise_HitRate,~,~,~] = multcompare(stats_HitRate,'CriticalValueType','lsd');
                save(fullfile(filesavepath,sprintf('Pvalue for Hit rate comparison_delay%d_%s.mat',iDelay,phase)),'tbl_HitRate','stats_HitRate','Pvalue_Pairwise_HitRate','-v7.3');
            end
            SetXYaxisProperty([],1,[],0.6,1.6+0.8*(numel(GroupName)-1),'Group',0,20,100,0,100,'Rates (%)',12,12);
            title(sprintf('p = %d',Pvalue_HitRate));
            box off;
            set(gcf, 'Renderer', 'Painter');
            saveas(gcf,fullfile(filesavepath,sprintf('Hit rates comparison-delay%d-%s',iDelay,phase)),'fig');
            close;

            % CR rate
            figure('Position',[219 303 600 900]);
            for iGroup = 1:numel(GroupName)
                plotBarAndError(ColorSet{iGroup},1.1+0.8*(iGroup-1),AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).CRRate,1);
                arrayfun(@(x) plot(1.1+0.8*(iGroup-1)+rand()*0.6-0.3,AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).CRRate(x,1),'o','MarkerSize',6,'MarkerFaceColor',ColorSet{iGroup},'MarkerEdgeColor','none'),1:numel(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).CRRate));
            end
            if numel(GroupName) == 2
                Pvalue_CRRate = ranksum(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).CRRate,AllSessionMiceBehavior{2}.(['delay' num2str(iDelay)]).CRRate);
            elseif numel(GroupName) > 2
                CRRate = []; GroupID = [];
                for iGroup = 1:numel(GroupName)
                    CRRate = [CRRate; AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).CRRate];
                    GroupID = [GroupID; iGroup*ones(numel(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).CRRate),1)];
                end
                [Pvalue_CRRate,tbl_CRRate,stats_CRRate] = anova1(CRRate,GroupID,'off');
                [Pvalue_Pairwise_CRRate,~,~,~] = multcompare(stats_CRRate,'CriticalValueType','lsd');
                save(fullfile(filesavepath,sprintf('Pvalue for CR rate comparison_delay%d_%s.mat',iDelay,phase)),'tbl_CRRate','stats_CRRate','Pvalue_Pairwise_CRRate','-v7.3');
            end 
            SetXYaxisProperty([],1,[],0.6,1.6+0.8*(numel(GroupName)-1),'Group',0,20,100,0,100,'Rates (%)',12,12);
            title(sprintf('p = %d',Pvalue_CRRate));
            box off;
            set(gcf, 'Renderer', 'Painter');
            saveas(gcf,fullfile(filesavepath,sprintf('CR rates comparison-delay%d-%s',iDelay,phase)),'fig');
            close;

            % 绘制d'柱状图
            figure('Position',[219 303 300 600]);
            for iGroup = 1:numel(GroupName)
                plotBarAndError(ColorSet{iGroup},1.1+0.8*(iGroup-1),AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).Dprime,1);
                arrayfun(@(x) plot(1.1+0.8*(iGroup-1)+rand()*0.6-0.3,AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).Dprime(x,1),'o','MarkerSize',6,'MarkerFaceColor',ColorSet{iGroup},'MarkerEdgeColor','none'),1:numel(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).Dprime));
            end
            if numel(GroupName) == 2
                Pvalue_Dprime = ranksum(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).Dprime,AllSessionMiceBehavior{2}.(['delay' num2str(iDelay)]).Dprime);
            elseif numel(GroupName) > 2
                Dprime = []; GroupID = [];
                for iGroup = 1:numel(GroupName)
                    Dprime = [Dprime; AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).Dprime];
                    GroupID = [GroupID; iGroup*ones(numel(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).Dprime),1)];
                end
                [Pvalue_Dprime,tbl_Dprime,stats_Dprime] = anova1(Dprime,GroupID,'off');
                [Pvalue_Pairwise_Dprime,~,~,~] = multcompare(stats_Dprime,'CriticalValueType','lsd');
                save(fullfile(filesavepath,sprintf('Pvalue for Dprime comparison_delay%d_%s.mat',iDelay,phase)),'tbl_Dprime','stats_Dprime','Pvalue_Pairwise_Dprime','-v7.3');
            end
            SetXYaxisProperty([],1,TimesID,0.5,1.7+0.8*(numel(GroupName)-1),'Group',0,1,3,0,4,'Dprime',12,12);
            title(sprintf('P=%d',Pvalue_Dprime));
            box off;
            set(gcf, 'Renderer', 'Painter');
            saveas(gcf,fullfile(filesavepath,sprintf('Dprime comparison-delay%d-%s',iDelay,phase)),'fig');
            close;

            % 绘制命中试次的舔舐率
            LickRate_Hit = cell(1,numel(GroupName));
            figure('Position',[219 303 750 600]);
            for iGroup = 1:numel(GroupName)
                tempLickRate_Hit = cellfun(@mean,AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).LickRate_Hit,'UniformOutput',false);
                LickRate_Hit{iGroup} = vertcat(tempLickRate_Hit{:});
                plotshadow(LickRate_Hit{iGroup},ColorSet{iGroup},2,3,-0.05-BeforeTrial,TimeGain);
            end
            % 聚类置换检验
            if numel(GroupName) == 2
                [tempSigTime_1,tempSigTime_2] = ClusterBasedPermutationTest_ForBothReal(LickRate_Hit{1},LickRate_Hit{2});
            else
                [tempSigTime_1,tempSigTime_2] = ClusterBasedPermutationTest_ForBothReal(LickRate_Hit{2},LickRate_Hit{3});
            end
            LabelSignificantPositions(tempSigTime_1-BeforeTrial*TimeGain,TimeGain,5,ColorSet{1});
            LabelSignificantPositions(tempSigTime_2-BeforeTrial*TimeGain,TimeGain,5,ColorSet{2});
            % 绘制事件曲线
            PlotEventCurve(SampOdorLen,DelayLen(iDelay),TestOdorLen,RespWindowLen,1,8);
            SetXYaxisProperty(-1*BeforeTrial,1,size(LickRate_Hit{1},2)/TimeGain-BeforeTrial,-0.3,size(LickRate_Hit{1},2)/TimeGain-BeforeTrial,'Time from sample onset (s)',...
                0,2,8,0,8,'Lick rate (Hz)',12,12);
            box off;
            set(gcf, 'Renderer', 'Painter');
            saveas(gcf,fullfile(filesavepath,sprintf('Lick rate comparison in Hit trials-delay%d trials-%s',iDelay,phase)),'fig');
            close;

            % 绘制舔舐效率柱状图
            figure('Position',[219 303 300 600]);
            for iGroup = 1:numel(GroupName)
                plotBarAndError(ColorSet{iGroup},1.1+0.8*(iGroup-1),AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).LickEfficiency,1);
                arrayfun(@(x) plot(1.1+0.8*(iGroup-1)+rand()*0.6-0.3,AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).LickEfficiency(x,1),'o','MarkerSize',6,'MarkerFaceColor',ColorSet{iGroup},'MarkerEdgeColor','none'),1:numel(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).LickEfficiency));
            end
            if numel(GroupName) == 2
                Pvalue_LickEfficiency = ranksum(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).LickEfficiency,AllSessionMiceBehavior{2}.(['delay' num2str(iDelay)]).LickEfficiency);
            elseif numel(GroupName) > 2
                LickEfficiency = []; GroupID = [];
                for iGroup = 1:numel(GroupName)
                    LickEfficiency = [LickEfficiency; AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).LickEfficiency];
                    GroupID = [GroupID; iGroup*ones(numel(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).LickEfficiency),1)];
                end
                [Pvalue_LickEfficiency,tbl_LickEfficiency,stats_LickEfficiency] = anova1(LickEfficiency,GroupID,'off');
                [Pvalue_Pairwise_LickEfficiency,~,~,~] = multcompare(stats_LickEfficiency,'CriticalValueType','lsd');
                save(fullfile(filesavepath,sprintf('Pvalue for LickEfficiency comparison_delay%d_%s.mat',iDelay,phase)),'tbl_LickEfficiency','stats_LickEfficiency','Pvalue_Pairwise_LickEfficiency','-v7.3');
            end
            SetXYaxisProperty([],1,TimesID,0.5,1.7+0.8*(numel(GroupName)-1),'Group',0,10,100,0,100,'Lick efficiency(%)',12,12);
            title(sprintf('P=%d',Pvalue_LickEfficiency));
            box off;
            set(gcf, 'Renderer', 'Painter');
            saveas(gcf,fullfile(filesavepath,sprintf('Lick efficiency comparison-delay%d-posttestodor%d-%s',iDelay,round(1000*LickEfficiencyWindowLen),phase)),'fig');
            close;
        end
    elseif strcmp(AnalysisStyle, 'Separation')
        % Plot hit and CR rates
        for iDelay = 1:numel(DelayLen)
            figure('Position',[219 303 750 600]);
            CompareDiffGroupsTimeLapsedBehavior(phase, 'Hit', ['delay' num2str(iDelay)], AllSessionMiceBehavior, ...
                ColorSet, LineWidth, LineStyle, MarkerShape, ColorSet, ColorSet, MarkerSize, filesavepath);
            CompareDiffGroupsTimeLapsedBehavior(phase, 'CR', ['delay' num2str(iDelay)], AllSessionMiceBehavior, ...
                ColorSet, LineWidth, LineStyle, MarkerShape, ColorSet, ColorSet, MarkerSize, filesavepath);
            legend(GroupName,'Location','southeast');
            legend('boxoff');
            % Set the coordinate axes
            SetXYaxisProperty(1,1,TimesNum,0.5,TimesNum+0.5,XaxisName,0,20,100,0,100,'Hit and CR rates (%)',TickLabelSize,AxisLabelSize);
            box off;
            set(gcf, 'Renderer', 'Painter');
            saveas(gcf,fullfile(filesavepath,sprintf('Hit and CR rates comparison-delay%d-%s',iDelay,phase)),'fig');
            close;
        end

        % Plot licking efficiencies
        for iDelay = 1:numel(DelayLen)
            figure('Position',[219 303 750 600]);
            CompareDiffGroupsTimeLapsedBehavior(phase, 'LickEfficiency', ['delay' num2str(iDelay)], AllSessionMiceBehavior, ...
                ColorSet, LineWidth, LineStyle, MarkerShape, ColorSet, ColorSet, MarkerSize, filesavepath);
            legend(GroupName,'Location','southeast');
            legend('boxoff');
            % Set the coordinate axes
            SetXYaxisProperty(1,1,TimesNum,0.5,TimesNum+0.5,XaxisName,0,20,100,0,100,'Licking efficiency (%)',TickLabelSize,AxisLabelSize);
            box off;
            set(gcf, 'Renderer', 'Painter');
            saveas(gcf,fullfile(filesavepath,sprintf('Lick efficiency comparison-delay%d-%s',iDelay,phase)),'fig');
            close;
        end

        % Plot Dprime
        if iLickEff == 1
            for iDelay = 1:numel(DelayLen)
                figure('Position',[219 303 750 600]);
                CompareDiffGroupsTimeLapsedBehavior(phase, 'Dprime', ['delay' num2str(iDelay)], AllSessionMiceBehavior, ...
                    ColorSet, LineWidth, LineStyle, MarkerShape, ColorSet, ColorSet, MarkerSize, filesavepath);            legend(GroupName,'Location','southeast');
                legend('boxoff');
                % Set the coordinate axes
                SetXYaxisProperty(1,1,TimesNum,0.5,TimesNum+0.5,XaxisName,0,20,100,0,100,'Performance (d")',TickLabelSize,AxisLabelSize);
                box off;
                set(gcf, 'Renderer', 'Painter');
                saveas(gcf,fullfile(filesavepath,sprintf('Dprime comparison-delay%d-%s',iDelay,phase)),'fig');
                close;
            end
        end

        % Plot the licking rate of hit trials
        for iDay = 1:TimesNum
            for iDelay = 1:numel(DelayLen)
                figure('Position',[219 303 750 600]);
                for iGroup = 1:numel(AllSessionMiceBehavior)
                    plotshadow(AllSessionMiceBehavior{iGroup}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},ColorSet{iGroup},2,3,-0.05-BeforeTrial,TimeGain);
                end
                % Cluster-based permutation test
                if numel(GroupName) == 3
                    [tempSigTime_group1,tempSigTime_group2] = ClusterBasedPermutationTest_ForBothReal(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},AllSessionMiceBehavior{2}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay});
                    LabelSignificantPositions(tempSigTime_group1-BeforeTrial*TimeGain,10,5,ColorSet{2});
                    LabelSignificantPositions(tempSigTime_group2-BeforeTrial*TimeGain,10,5,ColorSet{2});
                    [tempSigTime_group3,tempSigTime_group2] = ClusterBasedPermutationTest_ForBothReal(AllSessionMiceBehavior{3}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},AllSessionMiceBehavior{2}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay});
                    LabelSignificantPositions(tempSigTime_group3-BeforeTrial*TimeGain,10,5,ColorSet{3});
                    LabelSignificantPositions(tempSigTime_group2-BeforeTrial*TimeGain,10,5,ColorSet{3});
                elseif numel(GroupName) == 2
                    [tempSigTime_group1,tempSigTime_group2] = ClusterBasedPermutationTest_ForBothReal(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},AllSessionMiceBehavior{2}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay});
                    LabelSignificantPositions(tempSigTime_group1-BeforeTrial*TimeGain,10,5,ColorSet{2});
                    LabelSignificantPositions(tempSigTime_group2-BeforeTrial*TimeGain,10,5,ColorSet{2});
                end
                % Plot event curve
                PlotEventCurve(0,SampOdorLen,DelayLen(iDelay),TestOdorLen,RespWindowLen,2,8);
                SetXYaxisProperty(-1*BeforeTrial,1,size(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},2)/TimeGain-BeforeTrial,-0.3,size(AllSessionMiceBehavior{1}.(['delay' num2str(iDelay)]).LickRate_Hit{iDay},2)/TimeGain-BeforeTrial,'Time from sample onset (s)',...
                    0,2,8,0,8,'Lick rate (Hz)',TickLabelSize,AxisLabelSize);
                box off;
                set(gcf, 'Renderer', 'Painter');
                saveas(gcf,fullfile(filesavepath,sprintf('Lick rate comparison in hit trials-delay%d trials-day %d-%s',iDelay,iDay,phase)),'fig');
                close;
            end
        end
    end

    %% 保存小鼠分组信息
    save(fullfile(filesavepath,sprintf('%dGroupsMiceID_%s.mat',numel(GroupName),phase)),'GroupName','filename','-v7.3');