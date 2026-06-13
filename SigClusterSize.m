function [sigClusterSize, sigClusterIDs] = SigClusterSize(sigVector)
% SIGCLUSTERSIZE Calculate size and IDs of contiguous significant clusters
%   Input: sigVector - Binary vector (1 = significant, 0 = non-significant)
%   Outputs:
%   - sigClusterSize: Array of cluster sizes
%   - sigClusterIDs: Cell array of cluster indices

sigClusterSize = [];
sigClusterIDs = {};
if isempty(sigVector) || all(sigVector == 0)
    return;
end

% Find contiguous non-zero clusters
diffVec = diff([0; sigVector(:); 0] ~= 0);
startIdx = find(diffVec == 1);
endIdx = find(diffVec == -1) - 1;

% Calculate cluster sizes and IDs
for i = 1:length(startIdx)
    clusterIDs = startIdx(i):endIdx(i);
    sigClusterSize = [sigClusterSize length(clusterIDs)];
    sigClusterIDs{i} = clusterIDs;
end