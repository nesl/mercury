function [D,phi] = dtw_path_matrix(hele, hbaro)
% [p,q] = dp(M) 
%    Use dynamic programming to find a min-cost path through matrix M.
%    Return state sequence in p,q
% 2003-03-15 dpwe@ee.columbia.edu

% Copyright (c) 2003 Dan Ellis <dpwe@ee.columbia.edu>
% released under GPL - see file COPYRIGHT

r = numel(hele);
c = numel(hbaro);

% TODO consider dimaond area to make it more reasonable


% costs
D = zeros(r+1, c+1);
D(1,:) = NaN;
D(:,1) = NaN;
D(1,1) = 0;
D(2:(r+1), 2:(c+1)) = (hele' .* hele') * ones(1,c) - 2 * hele' * hbaro + ones(r,1) * (hbaro .* hbaro);

% traceback
phi = zeros(r,c);

for i = 1:r; 
  for j = 1:c;
    [dmax, tb] = min([D(i, j), D(i, j+1), D(i+1, j)]);
    D(i+1,j+1) = D(i+1,j+1)+dmax;
    phi(i,j) = tb;
  end
end

% Strip off the edges of the D matrix before returning
D = D(2:(r+1),2:(c+1));