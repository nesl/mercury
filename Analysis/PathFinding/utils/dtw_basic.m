function [score, mappedIdx, scoreAloneTheWay] = dtw_basic(elev_from_seg, elev_from_baro)
% [p,q] = dp(M) 
%    Use dynamic programming to find a min-cost path through matrix M.
%    Return state sequence in p,q
% 2003-03-15 dpwe@ee.columbia.edu

% Copyright (c) 2003 Dan Ellis <dpwe@ee.columbia.edu>
% released under GPL - see file COPYRIGHT

% How to use this:
%   TODO well, there are two ways to use this function but I'm too lazy to
%   explain it... Tell me if you want to know what's it's doing and I'll
%   update this part.........
%   okay I think i'm a little bit not responsible... in short one function
%   two purposes......

% Parameters:
%   The input hele is the elevation series of a certain trajectory.
%   The input hbaro is the barometer sensor value series, suppose with size N.
%   The output score and mappedIdx are N-element row vectors.
%       - score(a) means DTW( hele, hbaro(1:a) )
%       - mappedIdx(a) means which index of hele maps to hbaro(a)

% About pruning:
%   Assume we are processing ith element of barometer series. If we are on
%   the right path, then the minimum value of this column should be bound
%   below pruningFunction(i) (not a real function but a formula). Once it 
%   exceeds the pruning threshold, we don't process any more. The rest of the
%   elements in score will be inf, and mappedIdx will simply be an empty
%   array.

% About the transition:  (follows the matlab array directions)
%
%                         2nd dim, barometer (b / bIdx)
%               =======================================>>
%             ||
%             ||           2nd        *3rd*
%             ||           (s, b)     (s, b+1)
%   1st dim,  ||                 \       .
%   segment   ||                  \      .
%  (s / sIdx) ||                   \     .
%             ||      1st           v    v
%             ||      (s+1, b) ----> (s+1, b+1)
%             ||            
%             \/
%                      at the state your comparing seg(s) with baro(b)
%
%  The dot arrow is the gps-only transition, and in this version it's
%  blocked.
%

% reshape the input and make the parameters:
%    - hele as a column (y-axis) vector
%    - hbaro as a row (x-axis) vector
elev_from_seg = elev_from_seg(:);
elev_from_baro = elev_from_baro(:)';

numElementSeg = numel(elev_from_seg);
numElementBaro = numel(elev_from_baro);

costMatrix = (repmat(elev_from_seg, 1, numElementBaro) - repmat(elev_from_baro, numElementSeg, 1)) .^ 2;   % square
%costMatrix = ( abs(repmat(hele, 1, c) - repmat(hbaro, r, 1)) ) .^ 3 + 0.2;   % cube
%costMatrix = exp( abs(repmat(hele, 1, c) - repmat(hbaro, r, 1)) );  % exponential
%costMatrix

dp = inf(numElementSeg+1, numElementBaro+1);
from = zeros(numElementSeg+1, numElementBaro+1);
dp(1,1) = 0;

% for the pruning purpose we travel the barometer series (2nd dimension) as
% the outter loop and segment series (1st dimension) as the inner loop.
for bIdx = 1:numElementBaro
    for sIdx = 1:numElementSeg;
        %dp(j+1,k+1) = D(j+1,k+1) + min([D(j, k), D(j+1, k)]);
        [dp(sIdx+1, bIdx+1), from(sIdx+1, bIdx+1)] = min([ dp(sIdx+1, bIdx) dp(sIdx, bIdx) ]);
        dp(sIdx+1, bIdx+1) = dp(sIdx+1, bIdx+1) + costMatrix(sIdx, bIdx);
    end
    
    % pruning part. remember we consider anything related to bIdx, so
    % should be a column area.
    %if min( dp(2:end, bIdx) ) > 27 + 10*bIdx   % this is the pruning formula
    if min( dp(2:end, bIdx+1) ) > inf
        score = dp(end, 2:end);
        mappedIdx = [];
        scoreAloneTheWay = [];
        return;
    end
end

score = dp(end, 2:end);

% well, if the end corner is inf, there's no possible way to to
% back-tracking
if dp(end, end) == inf
    mappedIdx = [];
    scoreAloneTheWay = [];
    return;
end

% each barometer index can map to one or more segment indices
maxMappedIdx = zeros(1, numElementBaro);
minMappedIdx = ones(1, numElementBaro) * numElementSeg;

% back-tracking steps
backSteps = [
    0  -1
   -1  -1
];

sIdx = numElementSeg + 1;
bIdx = numElementBaro + 1;
while sIdx > 1 || bIdx > 1
    maxMappedIdx(bIdx-1) = max(maxMappedIdx(bIdx-1), sIdx-1);
    minMappedIdx(bIdx-1) = min(minMappedIdx(bIdx-1), sIdx-1);
    tmpFrom = from(sIdx, bIdx);
    sIdx = sIdx + backSteps(tmpFrom, 1);
    bIdx = bIdx + backSteps(tmpFrom, 2);
end
mappedIdx = round( (maxMappedIdx(1:end) + minMappedIdx(1:end)) / 2 );
scoreAloneTheWay = zeros(1, numElementBaro);
for bIdx = 1:numElementBaro
    scoreAloneTheWay(bIdx) = dp( maxMappedIdx(bIdx)+1, bIdx+1 );
end