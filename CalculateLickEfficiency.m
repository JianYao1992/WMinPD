function LickEfficiency = CalculateLickEfficiency(LickTs1,LickTs2,AnalysisRange)

LickNum1 = cellfun(@(x) nnz(x>AnalysisRange(1) & x<=AnalysisRange(2)),LickTs1,'UniformOutput',1);
LickNum2 = cellfun(@(x) nnz(x>AnalysisRange(1) & x<=AnalysisRange(2)),LickTs2,'UniformOutput',1);
LickEfficiency = 100*sum(LickNum1,1)/(sum(LickNum1,1)+sum(LickNum2,1));

