% Calculate mutual information (MI)
function MI = calcMI(SpkCount_S1,SpkCount_S2)

pool = [SpkCount_S1(:)',SpkCount_S2(:)']';
SpkCount_S1 = SpkCount_S1(:);
SpkCount_S2 = SpkCount_S2(:);
if max(pool) == min(pool)
    MI = 0;
    return;
end
prop_S1 = length(SpkCount_S1)/length(pool);
prop_S2 = length(SpkCount_S2)/length(pool);
pdf_S1 = fitdist(SpkCount_S1,'Poisson');
pdf_S2 = fitdist(SpkCount_S2,'Poisson');
pdf_All = fitdist(pool,'Poisson');
if max(SpkCount_S1)-min(SpkCount_S1) ~= 0
    MI_S1 = nansum(arrayfun(@(x) poisspdf(x,pdf_S1.lambda)*prop_S1*(log2(poisspdf(x,pdf_S1.lambda)/poisspdf(x,pdf_All.lambda))),0:120));
else
    MI_S1 = prop_S1*nansum(arrayfun(@(x) -log2(poisspdf(x,pdf_All.lambda)),0:120));
end
if max(SpkCount_S2)-min(SpkCount_S2) ~= 0
    MI_S2 = nansum(arrayfun(@(x) poisspdf(x,pdf_S2.lambda)*prop_S2*(log2(poisspdf(x,pdf_S2.lambda)/poisspdf(x,pdf_All.lambda))),0:120));
else
    MI_S2 = prop_S2*nansum(arrayfun(@(x) -log2(poisspdf(x,pdf_All.lambda)),0:120));
end
MI = MI_S1 + MI_S2;
