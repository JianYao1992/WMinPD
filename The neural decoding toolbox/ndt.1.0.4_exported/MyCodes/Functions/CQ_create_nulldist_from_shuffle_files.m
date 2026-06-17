function null_distributions=CQ_create_nulldist_from_shuffle_files(PermutationDecodingResultsDir,ShuffleDecodingTimes)

the_null_dist_dir = dir([PermutationDecodingResultsDir '*.mat']);
load([PermutationDecodingResultsDir the_null_dist_dir(1).name]);
if isstruct(DECODING_RESULTS)
    ReSampleNumPerFile=size(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results,1);
    BinNum=size(DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results,3);
else
    ReSampleNumPerFile=size(DECODING_RESULTS,1);
    BinNum=size(DECODING_RESULTS,2);
end

% null_distributions=zeros(ReSampleNumPerFile*size(the_null_dist_dir,1),BinNum);
null_distributions=zeros(ShuffleDecodingTimes,BinNum);
StartDecodingTime=0;
for iNullDist = 1:size(the_null_dist_dir,1)
    load([PermutationDecodingResultsDir the_null_dist_dir(iNullDist).name]);
    if isstruct(DECODING_RESULTS)
        CrossResampleDecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;
        CrossResampleDecodingResults=mean(CrossResampleDecodingResults,2);
        Size=size(CrossResampleDecodingResults);
        CrossResampleDecodingResults=reshape(CrossResampleDecodingResults,Size(1),Size(3));
    else
        Size=size(DECODING_RESULTS);
        CrossResampleDecodingResults=DECODING_RESULTS;        
    end
    
    %curr_null_results =curr_all_null_data.DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.mean_decoding_results;
    EndDecodingTime=StartDecodingTime+Size(1);
    tempDecodingTimes=EndDecodingTime-StartDecodingTime;
    if size(CrossResampleDecodingResults,2)>BinNum
        CrossResampleDecodingResults(:,1:40)=[];
    end
    null_distributions(StartDecodingTime+1:StartDecodingTime+Size(1),:,:)=CrossResampleDecodingResults(1:tempDecodingTimes,:,:);
    StartDecodingTime=StartDecodingTime+Size(1);
    if StartDecodingTime==ShuffleDecodingTimes
    break;
    end
end
