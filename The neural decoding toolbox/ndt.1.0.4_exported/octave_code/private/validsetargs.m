

function [x, y] = validsetargs (caller, x, y, byrows_arg)

  isallowedarraytype = @(x) isnumeric (x) || ischar (x) || islogical (x);

  if (nargin == 3)
    icx = iscellstr (x);
    icy = iscellstr (y);
    if (icx || icy)
      if (icx && ischar (y))
        y = cellstr (y);
      elseif (icy && ischar (x))
        x = cellstr (x);
      elseif (~ (icx && icy))
        error ('%s: cell array of strings cannot be combined with a nonstring value', caller);
      end
    elseif (~ (isallowedarraytype (x) && isallowedarraytype (y)))
      error ('%s: A and B must be arrays or cell arrays of strings', caller);
      end
  elseif (nargin == 4)
    if (~ strcmpi (byrows_arg, 'rows'))
      error ('%s: invalid option: %s', caller, byrows_arg);
    end

    if (iscell (x) || iscell (y))
      error ('%s: cells not supported with "rows"', caller);
    elseif (~ (isallowedarraytype (x) && isallowedarraytype (y)))
      error ('%s: A and B must be arrays or cell arrays of strings', caller);
    else
      if (ndims (x) > 2 || ndims (y) > 2)
        error ('%s: A and B must be 2-dimensional matrices for "rows"', caller);
      elseif (columns (x) ~= columns (y) && ~ (isempty (x) || isempty (y)))
        error ('%s: number of columns in A and B must match', caller);
      end
    end
  end





