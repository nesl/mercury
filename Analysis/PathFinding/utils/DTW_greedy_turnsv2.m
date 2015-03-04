function [ greedy_cost ] = DTW_greedy_turns( sensor_elev, sensor_turns, map_elev, map_turns )
% TEMPLATE = sensor turns
% PARTIAL = turns from segment of the map


%% Create Elevation cost matrix
% ^ partial
% |
%  ----> template
%
num_rows = length(map_elev);
num_cols = length(sensor_elev);

% Squared Error (SE) Cost Matrix
costMatrixElev = (repmat(map_elev, 1, num_cols) - repmat(sensor_elev', num_rows, 1)) .^ 2;


%% Create Turn cost matrix
% ^ partial
% |
%  ----> template
%
num_rows = length(map_turns);
num_cols = length(sensor_turns);

% Squared Error (SE) Cost Matrix
costMatrixTurns = zeros(num_rows, num_cols);
padding = 10;
for r=1:num_rows
    for c=1:num_cols
        
    end
end


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















