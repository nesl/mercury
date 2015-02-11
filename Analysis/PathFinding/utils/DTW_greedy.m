function [ greedy_cost ] = DTW_greedy( template, partial )
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

% First, if the partial is too small, just set the cost to be 0 (bad match)
if length(partial) == 1
    greedy_cost = 0;
    return;
end

% the greedy (partial) cost is the minimum cost solution that matches up to
% SOME point of the template, not necessarily the end of the template.
% However, if we don't reward longer matches somehow, we'll end up with
% trivially short solutions and our solver won't want to explore new paths.

% Therefore, the GREEDY cost should be the combination of cost and length
% that minimizes an expression like the following:

% cost/( length^e )

% where the exponent 'e' is a design variable.  Something between 0 and 1?
EXP = 1.0;
match_costs = Costs(end,:);
lengths = 1:size(Costs,2);
length_weights = -lengths.^EXP;
greedy_cost = min( length_weights./match_costs );

end















