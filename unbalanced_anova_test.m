function [p,tb1,stats] = unbalanced_anova_test(varargin)

data = [];
for i = 1:length(varargin)
    data = [data; varargin{i}];
end
factor1num = size(data,2); % column
factor2num = size(data,1); % row
factor1ID = []; factor2ID = []; testdata = cell(1,factor1num);
for i = 1:factor1num % column ID
    for j = 1:factor2num % row ID
        tempfactor1ID = i*ones(1,length(data{j,i}));
        factor1ID = [factor1ID tempfactor1ID];
        tempfactor2ID = j*ones(1,length(data{j,i}));
        factor2ID = [factor2ID tempfactor2ID];
    end
    testdata{1,i} = vertcat(data{:,i});
end
testdata = (vertcat(testdata{:}))';
[p,tb1,stats] = anovan(testdata,{factor2ID,factor1ID},'model','interaction','display','on');














