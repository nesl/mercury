function [ele_index] = dtw_find_path(hele, hbaro)
% [p,q] = dp(M) 
%    Use dynamic programming to find a min-cost path through matrix M.
%    Return state sequence in p,q
% 2003-03-15 dpwe@ee.columbia.edu

% Copyright (c) 2003 Dan Ellis <dpwe@ee.columbia.edu>
% released under GPL - see file COPYRIGHT

% Modified:
%   The input hele is the elevation series of a certain trajectory.
%   The input hbaro is the barometer sensor value series, suppose with size N.
%   The output is a row vector with the same number of elements with hbaro.
%       Each element represent the associate hele index.

% reshape the input and make the parameters:
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

% from direction index:
%
%  1 --> target
%       /   ^
%      /    |
%     /     |
%    /      |
%   2       3

% store the DTW result back to D
for j = 1:r; 
    for k = 1:c;
        [D(j+1,k+1), from(j+1, k+1)] = min([D(j+1, k), D(j, k), D(j, k+1)]);
        D(j+1,k+1) = D(j+1,k+1) + costMatrix(j,k);
    end
end

% now each hbaro index need to match to at least one hele index.
% since it might be more than one, we store it as a upper/lower range
upperEleInd = zeros(1, c);
lowerEleInd = ones(1, c) * r;

% back-tracking
backStep = [
    0  -1
   -1  -1
   -1   0
];
eind = r+1;  bind = c+1;  % index of elevation and barometer
while eind > 1 || bind > 1
    upperEleInd(bind-1) = max(upperEleInd(bind-1), eind-1);
    lowerEleInd(bind-1) = min(lowerEleInd(bind-1), eind-1);
    tfrom = from(eind, bind);
    eind = eind + backStep(tfrom, 1);
    bind = bind + backStep(tfrom, 2);
end


% copy the last row back to return matrix
ele_index = round( (upperEleInd(1:end) + lowerEleInd(1:end)) / 2 );

