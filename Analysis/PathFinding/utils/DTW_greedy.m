function [ costs ] = DTW_greedy( template, partial )
%DTW_GREEDY Summary of this function goes here
%   Detailed explanation goes here

%% Ensure inputs are column vectors
if ~iscolumn(template)
    template = template';
end

if ~iscolumn(partial)
    partial = partial';
end

%% Create cost matrix
% ^ partial
% |
%  ----> template
%
num_rows = length(partial);
num_cols = length(template);

% Squared Error (SE) Cost Matrix
costMatrix = (repmat(partial, 1, num_cols) - repmat(template', num_rows, 1)) .^ 2;

%% Find shortest path using dynamic programming
[~, ~, Costs] = dp(costMatrix);
costs = Costs;

end

