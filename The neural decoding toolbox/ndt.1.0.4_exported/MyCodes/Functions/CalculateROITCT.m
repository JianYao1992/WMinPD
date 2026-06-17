function [MeantempROIChRNLDiff,The95Percentile]=CalculateROITCT(DiffTCT,ROIRange,X)

tempROITrainBinID= X>=ROIRange(1)&X<ROIRange(2);
tempROITestBinID= X>=ROIRange(3)&X<ROIRange(4);
tempROIChRNLDiff=DiffTCT(:,tempROITrainBinID,tempROITestBinID);
MeantempROIChRNLDiff=mean(mean(tempROIChRNLDiff,3),2);

The95Percentile=prctile(MeantempROIChRNLDiff,[97.5,2.5 75 25]);

