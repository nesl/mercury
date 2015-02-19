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
%   the right path, then the minimum value of i-th column should be bound
%   by pruning_function(i). Thus, once it violate this condition, we
%   shouldn't continue performing DTW as it should be pruned out.
%
%   This is conceptually right but we're gonna use another pruning
%   strategy. Instead, we can prune directly during we calculate the
%   dynamic programming table. Consider the following observation:
%
%   dp:  0 X X X X X      X = impossible
%        X . . . H *      . = reasonable values
%        X X . . H @      H = the cost is too high and pruned by pruning function
%        X X X . . .      @ = cell of interest. it's gaurantee it must be pruned.
%        X X X X . .      * = don't care. it must be high in this example.
%        X X X X X .
%        X X X X X X
%
%   We found for each column (which has the same barometer index (bIdx)),
%   there's an upper bound and lower bound search index w.r.t segment index
%   (sIdx). The upper bound is naturely bounded by the fact of disallowing
%   the gps-only transition. The lower bound is derived by the following
%   sense. Please see the 4th column (the column with 2 Hs). After stepping
%   all the cells in this column we found the first two elements are higher
%   than the pruning threshold (denoted as H). Then we can argue that the
%   first two cells in dp table of the next column (5th column) shouldn't 
%   be visited because they should be pruned as the values are at least as
%   high as their left neighbors. Thus the lower bound is monotonic
%   increasing. Once the lower bound and upper bound is closed, then we
%   don't need to perform DTW anymore.
%
%   Finally, the second strategy implicitly includes the first one.
%
%
% What happened after being pruned:
%   Once every cells in one column are totally pruned, the rest of the
%   elements in scoreSeg will be marked as inf, mappedIdx and 
%   scoreAloneTheWay will simply be an empty array.


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

% the cost_function() is being called only once to get the best performance.
costMatrix = cost_function(repmat(elev_from_seg, 1, numElementBaro) - repmat(elev_from_baro, numElementSeg, 1));

dp = inf(numElementSeg+1, numElementBaro+1);
from = zeros(numElementSeg+1, numElementBaro+1);
dp(1,1) = 0;

segIdxStart = 1;

% for the pruning purpose we travel the barometer series (2nd dimension) as
% the outter loop and segment series (1st dimension) as the inner loop.
for bIdx = 1:numElementBaro
    segIdxEnd = min(bIdx, numElementSeg);
    for sIdx = segIdxStart:segIdxEnd;
        %dp(j+1,k+1) = D(j+1,k+1) + min([D(j, k), D(j+1, k)]);
        [dp(sIdx+1, bIdx+1), from(sIdx+1, bIdx+1)] = min([ dp(sIdx+1, bIdx) dp(sIdx, bIdx) ]);
        dp(sIdx+1, bIdx+1) = dp(sIdx+1, bIdx+1) + costMatrix(sIdx, bIdx);
    end
    
    % discuss: this should be considered the optimal way to implement
    % pruning as the pruning checking is amortized by ( (number of elements
    % of segments) + (number of elements in baro) ), corresponding the
    % while condition as pruning sucessfully and pruning failed.
    pruningScoreInThisRound = pruning_function(bIdx);
    while segIdxStart <= segIdxEnd && dp(segIdxStart+1, bIdx+1) > pruningScoreInThisRound  % low index of segment exceeds the score and should be pruned
        segIdxStart = segIdxStart + 1;
    end
    
    if segIdxStart > segIdxEnd  % lower bound meets upper bound, which implies all the elements are totally pruned
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