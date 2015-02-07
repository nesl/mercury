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

% the greedy (partial) cost is the minimum cost solution that matches up to
% SOME point of the template, not necessarily the end of the template.
% However, if we don't reward longer matches somehow, we'll end up with
% trivially short solutions and our solver won't want to explore new paths.

% Therefore, the GREEDY cost should be the combination of cost and length
% that minimizes an expression like the following:

% cost/( length^e )

% where the exponent 'e' is a design variable.  Something between 0 and 1?
EXP = 1;
match_costs = Costs(end,:);
lengths = 1:size(Costs,2);
length_weights = 1./( lengths.^EXP );
greedy_cost = min( match_costs.*length_weights );

end

