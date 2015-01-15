function [re] = all_pair_dtw_baro(hele, hbaro)
% [p,q] = dp(M) 
%    Use dynamic programming to find a min-cost path through matrix M.
%    Return state sequence in p,q
% 2003-03-15 dpwe@ee.columbia.edu

% Copyright (c) 2003 Dan Ellis <dpwe@ee.columbia.edu>
% released under GPL - see file COPYRIGHT

% modified:
% the input hele is the elevation series of a certain trajectory.
% the input hbaro is the barometer sensor value series, suppose with size N.
% the output re is an NxN matrix where re(a, b) means DTW( hbaro(a:b), hele).

r = numel(hele);
c = numel(hbaro);
re = zeros(c) * NaN;

% costs
for i = 1:c
    sb = hbaro(i:c);
    cc = c - i + 1;
    D = zeros(r+1, cc+1);
    D(1,:) = NaN;
    D(:,1) = NaN;
    D(1,1) = 0;
    D(2:(r+1), 2:(cc+1)) = (hele' .* hele') * ones(1,cc) - 2 * hele' * sb + ones(r,1) * (sb .* sb);

    for j = 1:r; 
        for k = 1:cc;
            D(j+1,k+1) = D(j+1,k+1) + min([D(j, k), D(j, k+1), D(j+1, k)]);
        end
    end
    
    re(i, i:end) = D(end, 2:end);
end

