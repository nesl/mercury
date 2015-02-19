function [re] = all_pair_dtw_baro(hele, hbaro)
% [p,q] = dp(M) 
%    Use dynamic programming to find a min-cost path through matrix M.
%    Return state sequence in p,q
% 2003-03-15 dpwe@ee.columbia.edu

% Copyright (c) 2003 Dan Ellis <dpwe@ee.columbia.edu>
% released under GPL - see file COPYRIGHT

% Modified:
%   The input hele is the elevation series of a certain trajectory.
%   The input hbaro is the barometer sensor value series, suppose with size N.
%   The output re is an NxN matrix where re(a, b) means DTW( hbaro(a:b), hele).
%   Both hele and hbaro are row vector 

% reshape the input and make the parameters:
%    - hele as a column (y-axis) vector
%    - hbaro as a row (x-axis) vector
hele = hele(:);
hbaro = hbaro(:)';

r = numel(hele);
c = numel(hbaro);

re = nan(c);

costMatrix = (repmat(hele, 1, c) - repmat(hbaro, r, 1)) .^ 2;   % square
%costMatrix = ( abs(repmat(hele, 1, c) - repmat(hbaro, r, 1)) ) .^ 3 + 0.2;   % cube
%costMatrix = exp( abs(repmat(hele, 1, c) - repmat(hbaro, r, 1)) );  % exponential
%costMatrix

% costs
for i = 1:c
    sb = hbaro(i:c);   % sub-segment of hbaro
    cc = numel(sb);
    
    D = zeros(r+1, cc+1);   % D is the sub-area of cost matrix
    D(1,:) = NaN;
    D(:,1) = NaN;
    D(1,1) = 0;
    D(2:end, 2:end) = costMatrix(:,i:end);
    
    % store the DTW result back to D
    for j = 1:r; 
        for k = 1:cc;
            %D(j+1,k+1) = D(j+1,k+1) + min([D(j, k), D(j, k+1), D(j+1, k)]);
            D(j+1,k+1) = D(j+1,k+1) + min([D(j, k), D(j+1, k)]);
        end
    end
    
    % copy the last row back to return matrix
    re(i, i:end) = D(end, 2:end);
end
