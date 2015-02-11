function [ s1trace, s2trace, mincost] = DTW_MSE( sig1, sig2 )
% cost = DTW_MSE( sig1, sig2 )
%
% minimum squared error (MSE)-based dynamic time warping (DTW)
% 

%% Ensure inputs are column vectors
if ~iscolumn(sig1)
    sig1 = sig1';
end

if ~iscolumn(sig2)
    sig2 = sig2';
end

%% Create cost matrix
% ^ sig2
% |
%  ----> sig1
%
num_rows = length(sig2);
num_cols = length(sig1);

% Squared Error (SE) Cost Matrix
costMatrix = (repmat(sig2, 1, num_cols) - repmat(sig1', num_rows, 1)) .^ 2;

%% Find shortest path using dynamic programming
[s1trace, s2trace, Costs] = dp(costMatrix);
mincost = Costs(end,end);

end

