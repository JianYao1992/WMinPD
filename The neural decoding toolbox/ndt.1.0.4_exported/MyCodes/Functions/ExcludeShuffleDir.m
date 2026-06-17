function SubPath=ExcludeShuffleDir(SubPath)

ShuffleDirID=[];
for i=1:size(SubPath,1)
   [~,temp]=fileparts(SubPath{i});
   IsShuffle=regexpi(temp,'Shuffle');
    if ~isempty(IsShuffle)
       ShuffleDirID=[ShuffleDirID i];
    end
end
SubPath(ShuffleDirID)=[];