function Ps = GetDataMatrixForMixedRepeatedAnova(Data,name)

between_group = [];
Mice_ID = [];
within_group = [];
performance = [];
TimeNum = numel(Data{1});
PrevMiceNum = 0;
for iGroup = 1:numel(Data)
    for iMouse = 1:numel(Data{iGroup}{1})
        between_group = [between_group; iGroup*ones(TimeNum,1)];
        Mice_ID = [Mice_ID; (iMouse+PrevMiceNum)*ones(TimeNum,1)];
        for iTime = 1:TimeNum
            within_group = [within_group; iTime];
            performance = [performance; Data{iGroup}{iTime}(iMouse)];
        end
    end
    PrevMiceNum = PrevMiceNum + numel(Data{iGroup}{1});
end
Frame = [performance between_group within_group Mice_ID];
[SSQs, DFs, MSQs, Fs, Ps] = mixed_between_within_anova(Frame,0,[name '_stat']);