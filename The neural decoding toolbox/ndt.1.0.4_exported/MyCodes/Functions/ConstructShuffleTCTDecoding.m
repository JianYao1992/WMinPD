function ShuffleTCTDecodingNullDistribution=ConstructShuffleTCTDecoding(ShuffleDecodingDir...
    ,ShuffleDecodingTimes,TimeBinNumber,step_size,StartTime)

ShuffleTCTDecodingNullDistribution=zeros(ShuffleDecodingTimes,TimeBinNumber,TimeBinNumber);
Path=pwd;
cd([Path '\' ShuffleDecodingDir])
ShuffleDecodingFiles=dir('*.mat*');
StartDecodingTime=0;
for iShuffleTCTDecoding=1:size(ShuffleDecodingFiles,1)
    load(ShuffleDecodingFiles(iShuffleTCTDecoding).name)
    
    if isstruct(DECODING_RESULTS)
        tempShuffleTCTDecodingResults=DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.decoding_results;
        tempShuffleTCTDecodingResults=mean(tempShuffleTCTDecodingResults,2);
        Size=size(tempShuffleTCTDecodingResults);
        tempShuffleTCTDecodingResults=reshape(tempShuffleTCTDecodingResults,Size(1),Size(3),Size(4));
    else
        tempShuffleTCTDecodingResults=DECODING_RESULTS;
        Size=size(tempShuffleTCTDecodingResults);
    end
    BinNumPerSecond=1000/step_size;
    RemoveBaseline=4-StartTime-1;
    RemoveBaselineBinNum=RemoveBaseline*BinNumPerSecond;
    StartBin=RemoveBaselineBinNum+1;
    EndBin=StartBin+100-1;
    if EndBin>size(tempShuffleTCTDecodingResults,3)
        StartBin=1;
        EndBin=size(tempShuffleTCTDecodingResults,3);
    end
    if StartDecodingTime+Size(1)>ShuffleDecodingTimes
        EndDecodingTime=ShuffleDecodingTimes;
    else
        EndDecodingTime=StartDecodingTime+Size(1);
    end
    tempDecodingTimes=EndDecodingTime-StartDecodingTime;
    ShuffleTCTDecodingNullDistribution(StartDecodingTime+1:EndDecodingTime,StartBin:EndBin,StartBin:EndBin)=tempShuffleTCTDecodingResults(1:tempDecodingTimes,StartBin:EndBin,StartBin:EndBin);
    StartDecodingTime=StartDecodingTime+Size(1);
end
cd(Path)