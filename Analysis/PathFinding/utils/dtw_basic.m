function [scoreSeg, mappedIdx, scoreAloneTheWay] = dtw_basic(elev_from_seg, elev_from_baro, cost_function, pruning_function)
% [p,q] = dp(M) 
%    Use dynamic programming to find a min-cost path through matrix M.
%    Return state sequence in p,q
% 2003-03-15 dpwe@ee.columbia.edu

% Copyright (c) 2003 Dan Ellis <dpwe@ee.columbia.edu>
% released under GPL - see file COPYRIGHT

% How to use this:
%   This function support one of the following queries:
%   1. you want to get the DTW of segment series compared to all the possible
%      starting sub segments of baro series (i.e., a row vector which is
%      the score of DTW(seg, baro(1:1)), DTW(seg, baro(1:2), ...). The
%      result is stored in scoreSeg.
%   2. you want to map the baro series to the corresponding segment series,
%      the result is stored in mappedIdx
%   3. you are curious about the changes of dtw score alone the searching
%      path (in the dynamic programming table). The result is stored in
%      scoreAloneTheWay
%   These three questions are independent, yet the computations are hugely
%   overlapped. The function retures all the three answers at once, but
%   it's up to the result consumer to use the result they're looking for.
%
% Minor issues:
%   Apparently if we're only curious about scoreSeg, we don't need the
%   back-tracking stage and can stop the function earlier. However, since
%   the back-tracking part is O(n) compared to dp stage is O(n^2), thus I
%   consider the overhead is small.

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

% CONSIDER: more pruning
%   There's still a possibility to prune in the dynamic programming part.
%   So far we only disallow the gps-only transition, which is upper bound
%   pruning (in terms of index), but it is also possible to have lower
%   bound pruning.
%
%   DP:  0 X X X X X      X = impossible
%        X . . . H H      . = reasonable values
%        X X . . H @      H = the cost is too high and pruned by pruning function
%        X X X . . .      @ = cell of interest. it's gaurantee it must be pruned.
%        X X X X . .
%        X X X X X .
%        X X X X X X
%
%  So the starting index of segment (sIdx) will monotonicly increase.

% reshape the input and make the parameters:
%    - hele as a column (y-axis) vector
%    - hbaro as a row (x-axis) vector
elev_from_seg = elev_from_seg(:);
elev_from_baro = elev_from_baro(:)';

numElementSeg = numel(elev_from_seg);
numElementBaro = numel(elev_from_baro);

costMatrix = cost_function(repmat(elev_from_seg, 1, numElementBaro) - repmat(elev_from_baro, numElementSeg, 1));

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
    if min( dp(2:end, bIdx+1) ) > pruning_function(bIdx)
        scoreSeg = dp(end, 2:end);
        mappedIdx = [];
        scoreAloneTheWay = [];
        return;
    end
end

scoreSeg = dp(end, 2:end);

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