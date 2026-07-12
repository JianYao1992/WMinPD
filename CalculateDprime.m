function dprime = CalculateDprime(TrialStructure)

HitRate = nnz(TrialStructure(:,7)==1)/(nnz(TrialStructure(:,7)==1)+nnz(TrialStructure(:,7)==2));
FalseRate = nnz(TrialStructure(:,7)==3)/(nnz(TrialStructure(:,7)==3)+nnz(TrialStructure(:,7)==4));
GoTrialsNum = nnz(TrialStructure(:,7)==1 | TrialStructure(:,7)==2);
NoGoTrialsNum = nnz(TrialStructure(:,7)==3 | TrialStructure(:,7)==4);
if HitRate==1
    a = 1-1/(2*GoTrialsNum);
elseif HitRate == 0
    a = 1/(2*GoTrialsNum);
else
    a = norminv(HitRate);
end
if FalseRate==1
    b = 1-1/(2*NoGoTrialsNum);
elseif FalseRate == 0
    b = 1/(2*NoGoTrialsNum);
else
    b = norminv(FalseRate);
end
dprime = a-b;
end
