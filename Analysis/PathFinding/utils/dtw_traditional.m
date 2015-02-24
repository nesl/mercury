function score = dtw_traditional(hele, hbaro)
% [p,q] = dp(M) 
%    Use dynamic programming to find a min-cost path through matrix M.
%    Return state sequence in p,q
% 2003-03-15 dpwe@ee.columbia.edu

% Copyright (c) 2003 Dan Ellis <dpwe@ee.columbia.edu>
% released under GPL - see file COPYRIGHT

% reshape the input and make the parameters: (shouldn't be named as hele
% and hbaro. should name them series_a, series_b.
%    - hele as a column (y-axis) vector
%    - hbaro as a row (x-axis) vector
hele = hele(:);
hbaro = hbaro(:)';

r = numel(hele);
c = numel(hbaro);

re = nan(c);

costMatrix = (repmat(hele, 1, c) - repmat(hbaro, r, 1)) .^ 2;

D = zeros(r+1, c+1);
D(1,:) = NaN;
D(:,1) = NaN;
D(1,1) = 0;
from = zeros(r+1, c+1);

% store the DTW result back to D
for j = 1:r; 
    for k = 1:c;
        [D(j+1,k+1), from(j+1, k+1)] = min([D(j+1, k), D(j, k), D(j, k+1)]);
        D(j+1,k+1) = D(j+1,k+1) + costMatrix(j,k);
    end
end

score = D(end, end);