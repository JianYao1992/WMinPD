function [RealDecodingResultsSigClusterSize,RealDecodingResultsSigClusterID]=CalculateSignificantClusterSize(TimeLampsedIsSignificantBin)

TestBinNum=length(TimeLampsedIsSignificantBin);

RealDecodingResultsSigClusterSize=[];
RealDecodingResultsSigClusterID=[];
SigClusterSize=0;
SigClusterBinID=[];
for iTestBin = 2:TestBinNum%go through each test bin
    if iTestBin==2&&TimeLampsedIsSignificantBin(iTestBin-1)==1
        SigClusterSize=1;
        SigClusterBinID=[SigClusterBinID 1];
    end
    if TimeLampsedIsSignificantBin(iTestBin)==1&&TimeLampsedIsSignificantBin(iTestBin-1)==1
        SigClusterSize=SigClusterSize+1;
        SigClusterBinID=[SigClusterBinID iTestBin];
        if iTestBin==TestBinNum
            RealDecodingResultsSigClusterSize=[RealDecodingResultsSigClusterSize SigClusterSize];
            RealDecodingResultsSigClusterID=[RealDecodingResultsSigClusterID {SigClusterBinID}];
        end
    elseif TimeLampsedIsSignificantBin(iTestBin)==1&&TimeLampsedIsSignificantBin(iTestBin-1)==0
        SigClusterSize=1;
        SigClusterBinID=iTestBin;
    else
        if SigClusterSize>0
            RealDecodingResultsSigClusterSize=[RealDecodingResultsSigClusterSize SigClusterSize];
            RealDecodingResultsSigClusterID=[RealDecodingResultsSigClusterID {SigClusterBinID}];
        end
        SigClusterSize=0;
        SigClusterBinID=[];
    end
end


