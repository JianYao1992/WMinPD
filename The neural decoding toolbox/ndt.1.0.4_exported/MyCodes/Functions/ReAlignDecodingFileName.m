function AllDecodingResultsName=ReAlignDecodingFileName(LaserGroup,DecodingResults)

AllDecodingResultsName={LaserGroup.name};   
DecodingResults=struct2cell(DecodingResults)';
DecodingResults=DecodingResults(:,1);    
NoLaserGroup=setdiff(DecodingResults,AllDecodingResultsName);    
AllDecodingResultsName=[NoLaserGroup;AllDecodingResultsName];
