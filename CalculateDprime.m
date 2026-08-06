function dprime = CalculateDprime(TrialStructure)

OutcomeColumn = 5;
HitRate = nnz(TrialStructure(:,OutcomeColumn)==1)/(nnz(TrialStructure(:,OutcomeColumn)==1)+nnz(TrialStructure(:,OutcomeColumn)==2));
FalseRate = nnz(TrialStructure(:,OutcomeColumn)==3)/(nnz(TrialStructure(:,OutcomeColumn)==3)+nnz(TrialStructure(:,OutcomeColumn)==4));
GoTrialsNum = nnz(TrialStructure(:,OutcomeColumn)==1 | TrialStructure(:,OutcomeColumn)==2);
NoGoTrialsNum = nnz(TrialStructure(:,OutcomeColumn)==3 | TrialStructure(:,OutcomeColumn)==4);
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
