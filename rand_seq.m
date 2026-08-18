function f = rand_seq(len, n, m)
%RAND_SEQ Randomly distribute an exact total across a fixed number of trials.
%   f = RAND_SEQ(len, n, m) returns a 1-by-n int16 vector satisfying:
%       sum(double(f)) == len
%       0 <= f(i) <= m
%
%   Example:
%       f = rand_seq(50, 24, 9);

validateattributes(len, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'nonnegative'}, ...
    mfilename, 'len', 1);
validateattributes(n, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'positive'}, ...
    mfilename, 'n', 2);
validateattributes(m, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'nonnegative'}, ...
    mfilename, 'm', 3);

% Use double internally so integer-class inputs cannot overflow in n*m or
% change the behavior of division below.
len = double(len);
n = double(n);
m = double(m);

if len > n * m
    error('rand_seq:ImpossibleAllocation', ...
        'Cannot distribute %d items across %d trials with a maximum of %d per trial.', ...
        len, n, m);
end

if m > double(intmax('int16'))
    error('rand_seq:OutputOverflow', ...
        'm must not exceed intmax(''int16'') because the output is int16.');
end

if len == 0
    f = zeros(1, n, 'int16');
    return;
end

% Regard every trial as having m available capacity slots. Randomly selecting
% exactly len distinct slots guarantees both the requested total and the
% per-trial maximum without rounding or iterative correction.
selectedSlots = randperm(n * m, len);
selectedTrials = ceil(selectedSlots ./ m);
f = accumarray(selectedTrials(:), 1, [n, 1], @sum, 0).';
f = int16(f);

% Defensive check: these conditions must hold for every returned sequence.
assert(numel(f) == n && sum(double(f)) == len && ...
    all(f >= 0) && all(double(f) <= m), ...
    'Generated sequence does not satisfy the requested constraints.');
end
