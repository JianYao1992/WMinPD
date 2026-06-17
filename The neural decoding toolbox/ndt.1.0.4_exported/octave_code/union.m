

function [y, ia, ib] = union (a, b, varargin)

  if (nargin < 2 || nargin > 3)
    print_usage ();
  end

    

  by_rows = nargin == 3;
  isrowvec = isvector (a) && isvector (b) && isrow (a) && isrow (b);

  
  % Modified by Ethan to deal with creating a union between an empty vector and a cell array
  if isempty(a)
    if by_rows
      y = unique(b, 'rows');
    else
      y = unique(b);
    end
    return
  end
    
 if isempty(b)
    if by_rows
      y = unique(a, 'rows');
    else
      y = unique(a);
    end
    return
 end
  
  
 [a, b] = validsetargs ('union', a, b, varargin{:});

  
  if (by_rows)
    y = [a; b];
  else
    y = [a(:); b(:)];
    
    if (isrowvec)
      y = y.';
    end
  end

  if (nargout <= 1)
    y = unique (y, varargin{:});
  else
    [y, idx] = unique (y, varargin{:});
    na = numel (a);
    ia = idx(idx <= na);
    ib = idx(idx > na) - na;
  end




%!assert (union ([1, 2, 4], [2, 3, 5]), [1, 2, 3, 4, 5])
%!assert (union ([1; 2; 4], [2, 3, 5]), [1; 2; 3; 4; 5])
%!assert (union ([1; 2; 4], [2; 3; 5]), [1; 2; 3; 4; 5])
%!assert (union ([1, 2, 3], [5; 7; 9]), [1; 2; 3; 5; 7; 9])


%!test
%! a = rand (3,3,3);
%! b = a;
%! b(1,1,1) = 2;
%! assert (union (a, b), sort ([a(1:end)'; 2]));

%!test
%! a = [3, 1, 4, 1, 5];
%! b = [1, 2, 3, 4];
%! [y, ia, ib] = union (a, b.');
%! assert (y, [1; 2; 3; 4; 5]);
%! assert (y, sort ([a(ia)'; b(ib)']));


%!error <cell array of strings cannot be combined> union ({"a"}, 1)
%!error <A and B must be arrays or cell arrays> union (@sin, 1)
%!error <invalid option: columns> union (1, 2, "columns")
%!error <cells not supported with "rows"> union ({"a"}, {"b"}, "rows")
%!error <A and B must be arrays or cell arrays> union (@sin, 1, "rows")
%!error <A and B must be 2-dimensional matrices> union (rand(2,2,2), 1, "rows")
%!error <number of columns in A and B must match> union ([1 2], 1, "rows")

