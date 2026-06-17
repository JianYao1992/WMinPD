function [RealCrossReSampleDecodingResults,RealDecodingResults,RealTCTDecodingStd,TimeBinNumber]...
    =ConstruceNDTRealDecodingResults(AllDecodingFile,DecodingTimes)

load(AllDecodingFile(1).name)
if exist('DECODING_RESULTS1','var')
    DECODING_RESULTS=DECODING_RESULTS1;
elseif exist('DECODING_RESULTS2','var')
    DECODING_RESULTS=DECODING_RESULTS2;
end
if isstruct(DECODING_RESULTS)
    Size=size(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results);
else
    Size=size(DECODING_RESULTS);
end
RealCrossReSampleDecodingResults=zeros(DecodingTimes,Size(end));
Start=0;
for iFile=1:size(AllDecodingFile,1)
    load(AllDecodingFile(iFile).name)
    if exist('DECODING_RESULTS1','var')
        DECODING_RESULTS=DECODING_RESULTS1;
    elseif exist('DECODING_RESULTS2','var')
        DECODING_RESULTS=DECODING_RESULTS2;
    end    
     if isstruct(DECODING_RESULTS)
        CVMean=mean(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results,2);
        CVMean=reshape(CVMean,size(CVMean,1),size(CVMean,3));
    else
        CVMean=DECODING_RESULTS;
     end    
    
    if Start+size(CVMean,1)>DecodingTimes
        EndID=DecodingTimes;
    else
        EndID=Start+size(CVMean,1);
    end
    RealCrossReSampleDecodingResults(Start+1:EndID,:)=CVMean(1:EndID-Start,:);
    Start=Start+size(CVMean,1);
    if Start>=DecodingTimes
        break;
    end
end
RealDecodingResults=smooth(mean(RealCrossReSampleDecodingResults,1))';
RealTCTDecodingStd=std(RealCrossReSampleDecodingResults,1)';
TimeBinNumber=Size(end);
