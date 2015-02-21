function [ greedy_cost ] = DTW_greedy_turns( template, partial )
% TEMPLATE = sensor turns
% PARTIAL = turns from segment of the map

%% Ensure inputs are column vectors
if ~iscolumn(template)
    template = template';
end

if ~iscolumn(partial)
    partial = partial';
end

%% If partial is empty (no turns detected yet in the path) make a dummy "0 deg." turn
if isempty(partial)
    partial = 0;
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

% costs to various template segments
match_costs = 1e-5*Costs(end,:);

% length weights
lengths = 1:size(Costs,2);
MIN_PARTIAL = 0;
length_weights = max( (lengths - MIN_PARTIAL), 0).^0.0;

% final greedy cost
[greedy_cost, idx] = min( -length_weights./(match_costs+1) );
% plot(-length_weights./(match_costs+1));
% pause();

%fprintf(' %d /( %.2f + 1)\n', length_weights(idx), match_costs(idx));


end















