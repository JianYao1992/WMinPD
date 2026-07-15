function bsvalue = BootstrapCalculation(originaldata,bstimes,samplingsize)

originaldata = originaldata(:);
rng('shuffle');
bsvalue = [];
for itr = 1:bstimes
    bsorder = randperm(numel(originaldata));
    bsdata = originaldata(bsorder(1:samplingsize));
    bsdata = bsdata(:);
    bsvalue = [bsvalue; mean(bsdata)];
end
