function [ greedy_cost ] = DTW_greedy( template, partial )
% TEMPLATE = sensor
% PARTIAL = segment of the map

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

% what is the entropy of this partial candidate? if we have a good match
% with a higher entropy, that's more significant than a good match with a
% low entropy.  
ent = entropy(partial./max(partial));

% costs to various template segments
match_costs = Costs(end,:);

% length weights
lengths = 1:size(Costs,2);
MIN_PARTIAL = 10;
length_weights = max( (lengths - MIN_PARTIAL), 0).^1.5;

% final greedy cost
[greedy_cost,idx] = min( -length_weights./(match_costs+1) );

%fprintf(' %.2f * %d / %.5f = %.2f\n', ent, idx, match_costs(idx)+1, greedy_cost);

end















