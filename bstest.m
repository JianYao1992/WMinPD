function p = bstest(bsdata1,bsdata2)

bsdata1 = bsdata1(:);
bsdata2 = bsdata2(:);
diffvalue = bsdata1 - bsdata2;
if mean(diffvalue)<=0
    p = nnz(diffvalue>=0)/numel(diffvalue);
else
    p = nnz(diffvalue<=0)/numel(diffvalue);
end