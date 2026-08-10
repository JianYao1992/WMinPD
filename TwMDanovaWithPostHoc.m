
function TwMDanovaWithPostHoc(Data,filename)

GroupName = {'Monomer injection','PFF injection','PFF injection activation'};
between_group = cell(0);
Mice_ID = [];
performance = [];
TimeNum = numel(Data{1});
PrevMiceNum = 0;
for iGroup = 1:numel(Data)
    for iMouse = 1:numel(Data{iGroup}{1})
        tempPerf = [];
        between_group{end+1,1} = GroupName{iGroup};
        Mice_ID = [Mice_ID; iMouse+PrevMiceNum];
        for iTime = 1:TimeNum
            tempPerf = [tempPerf Data{iGroup}{iTime}(iMouse)];
        end
        performance = [performance; tempPerf];
    end
    PrevMiceNum = PrevMiceNum + numel(Data{iGroup}{1});
end

%% Tw-md-ANOVA test with post hoc analysis
T = table(Mice_ID, categorical(between_group), ...
    performance(:,1), performance(:,2), performance(:,3), performance(:,4),...
    performance(:,5), performance(:,6), ...
    'VariableNames', ...
    {'Mouse','Group','Day1','Day2','Day3','Day4','Day5','Day6'});

% 'Day' is the within-subject factor
within = table(categorical((1:6)'), 'VariableNames', {'Day'});
rm = fitrm(T, 'Day1-Day6 ~ Group', 'WithinDesign', within);

Stat_BetweenTbl = anova(rm);
% disp(Stat_BetweenTbl);
cmpGroupPostHoc = multcompare(rm, 'Group', 'ComparisonType', 'lsd');
% disp(cmpGroupPostHoc);
save(filename,'Stat_BetweenTbl','cmpGroupPostHoc','-v7.3');
