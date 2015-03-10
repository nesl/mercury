function dpScore = dp3(M)
% [p,q] = dp(M) 
%    Use dynamic programming to find a min-cost path through matrix M.
%    Return state sequence in p,q
% 2003-03-15 dpwe@ee.columbia.edu

% Copyright (c) 2003 Dan Ellis <dpwe@ee.columbia.edu>
% released under GPL - see file COPYRIGHT

[r,c] = size(M);

% costs
D = zeros(r+1, c+1);
D(1,:) = NaN;
D(:,1) = NaN;
D(1,1) = 0;
D(2:(r+1), 2:(c+1)) = M;

% traceback
phi = zeros(r,c);

%{
for i = 1:r; 
  for j = 1:c;
    [dmax, tb] = min([D(i, j), D(i, j+1), D(i+1, j)]);
    D(i+1,j+1) = D(i+1,j+1)+dmax;
    phi(i,j) = tb;
  end
end
%}

%r
%c
Df = D(:)';
s = r+3;
l = r+c-1;
e = s + (l-1) * r;
candidate = s:r:e;
lidx = 1;
ridx = 1;
for i = 1:l
    %candidate(lidx:ridx)
    Df(candidate(lidx:ridx)) = Df(candidate(lidx:ridx)) + min( [Df(candidate(lidx:ridx)-1); Df(candidate(lidx:ridx)-r-1); Df(candidate(lidx:ridx)-r-2) ] );
    %candidate(lidx:ridx)
    %[Df(candidate(lidx:ridx)-1); Df(candidate(lidx:ridx)-r-1); Df(candidate(lidx:ridx)-r-2) ] 
    %candidate(lidx:ridx)-1
    %candidate(lidx:ridx)-r-1
    %candidate(lidx:ridx)-r-2
    candidate = candidate + 1;
    if i >= r
        lidx = lidx + 1;
    end
    if i < c
        ridx = ridx + 1;
    end
    
end

D = reshape(Df', [], c+1);
dpScore = D(2:end, 2:end);
%Df