function [ greedy_cost ] = DTW_greedy_elev_turn( elevTemplate, turnTemplate, elevPartial, turnPartial )
% TEMPLATE = sensor
% PARTIAL = segment of the map

%% constants
tolerateTurnDelay = 4;
tolerateAngleDrift = 45;
numCandidatesToKeep = 3;

%% Let's make 1st dim (partial) as column and 2nd dim (template) as row

%  ----> template (sensor)
% |
% v
% partial (map)

if ~iscolumn(elevPartial)
    elevPartial = elevPartial';
end
if ~iscolumn(turnPartial)
    turnPartial = turnPartial';
end

if ~isrow(elevTemplate)
    elevTemplate = elevTemplate';
end
if ~isrow(turnTemplate)
    turnTemplate = turnTemplate';
end



%% Create cost matrix



% guide: partial matches a portion of template

num_rows = length(elevPartial);
num_cols = length(elevTemplate);

% Squared Error (SE) Cost Matrix


%% Find shortest path using dynamic programming

% the greedy (partial) cost is the minimum cost solution that matches up to
% SOME point of the template, not necessarily the end of the template.
% However, if we don't reward longer matches somehow, we'll end up with
% trivially short solutions and our solver won't want to explore new paths.

% Therefore, the GREEDY cost should be the combination of cost and length

% what is the entropy of this partial candidate? if we have a good match
% with a higher entropy, that's more significant than a good match with a
% low entropy.  


partialMaxAcceptTurn = turnPartial;
partialMinAcceptTurn = turnPartial;
partialShiftLeft  = turnPartial;
partialShiftRight = turnPartial;
for i = 1:tolerateTurnDelay
    partialShiftLeft  = [partialShiftLeft(1:end-1) ; turnPartial(end)];
    partialShiftRight = [turnPartial(1) ; partialShiftRight(2:end)];
    partialMaxAcceptTurn = max(partialMaxAcceptTurn, partialShiftLeft);
    partialMaxAcceptTurn = max(partialMaxAcceptTurn, partialShiftRight);
    partialMinAcceptTurn = min(partialMinAcceptTurn, partialShiftLeft);
    partialMinAcceptTurn = min(partialMinAcceptTurn, partialShiftRight);
end

partialMaxAcceptTurn = partialMaxAcceptTurn + tolerateAngleDrift;
partialMinAcceptTurn = partialMinAcceptTurn - tolerateAngleDrift;

% GUIDE: from now on, shift everything for one unit
num_dp_rows = num_rows + 1;
num_dp_cols = num_cols + 1;

elevCostMatrix = zeros(num_dp_rows, num_dp_cols);
elevCostMatrix(2:end, 2:end) = (repmat(elevPartial, 1, num_cols) - repmat(elevTemplate, num_rows, 1)) .^ 2;

turnCostMatrix = false(num_rows+1, num_cols+1);
tmpTemplateTurnMat = repmat(turnTemplate, num_rows, 1);
turnCostMatrix(2:end, 2:end) = ~( ( repmat(partialMinAcceptTurn, 1, num_cols) <= tmpTemplateTurnMat ...
                                    & tmpTemplateTurnMat <= repmat(partialMaxAcceptTurn, 1, num_cols) ) );

% sadly, the significant dimension for matlab is that last dimension.
% thus, each element in dp is: dp(metric, candidate, pIdx, tIdx)
%
% Explanation: for each state dp(:, :, pIdx, tIdx):
%                  each stores a list of candidates:
%                       each candidate is (elevScore, # of turn mistakes)

dp = inf(2, numCandidatesToKeep, num_dp_rows, num_dp_cols);  
dp(:, 1, 1, 1) = [0, 1];  % need to have first turn mistake, otherwise it's always be 0....

firstPartialIndx = 2;

for idxt = 2:num_dp_cols   % last dimension first for performance purpose
    lastPartialIndex = min(idxt, num_dp_rows);
    for idxp = firstPartialIndx:lastPartialIndex
        %fprintf('idxt=%d, idxp=%d\n', idxt, idxp);
        candidates = [dp(:, :, idxp, idxt-1) dp(:, :, idxp-1, idxt-1)];
        [~, rank] = sort(candidates(1,:) .* candidates(2,:));
        raw = candidates(:, rank(1:numCandidatesToKeep) );
        raw(1,:) = raw(1,:) + elevCostMatrix(idxp, idxt);
        raw(2,:) = raw(2,:) + turnCostMatrix(idxp, idxt);
        dp(:, :, idxp, idxt) = raw;
    end
    
    %fprintf('----------------------------------------\n');
    %dp(:, 1, lastPartialIndex, idxt)
    %dp(:, :, firstPartialIndx, idxt)
    %pause
    while firstPartialIndx < lastPartialIndex ...
            && dp(1, 1, lastPartialIndex, idxt) <= min( dp(1, :, firstPartialIndx, idxt), [], 2 ) ...
            && dp(2, 1, lastPartialIndex, idxt) <= min( dp(2, :, firstPartialIndx, idxt), [], 2 )
        firstPartialIndx = firstPartialIndx + 1;
        %dp(:, 1, lastPartialIndex, idxt)
        %dp(:, :, firstPartialIndx, idxt)
        %pause
    end
    %fprintf('=======================================\n');
end
        
% GUIDE: back to non-shift world

match_costs = squeeze( dp(1, 1, end, 2:end) .* dp(2, 1, end, 2:end) )';
%squeeze( dp(1, 1, end, 2:end) )
%squeeze( dp(2, 1, end, 2:end) )

% get variance
variance = var(elevPartial);

% length weights
MIN_PARTIAL = 10;
%length_weights = max( ( (1:num_cols) - MIN_PARTIAL), 0);
%length_weights = max( ( (1:num_cols) - MIN_PARTIAL), 0).^4.0;
%length_weights = 1.0 ./ (0.0953021720878382 * log( (1:num_cols) - 0.305351521101538 ) + 0.61305616981424);

length_weights = max( ( (1:num_cols) - MIN_PARTIAL), 0) .* (2 .^ ((1:num_cols) / 30));

% cost of going this speed
SR = (1/1); % windowed baro / sec
times = num_cols/SR;
latlng_dist = 10; % meters / latlng sample
dist = length(elevPartial)*latlng_dist;
avg_speeds = dist./times;
%% TEMPORARILY REMOVE SPEED COSTS TO DEBUG
%speed_costs = calculateSpeedCost(avg_speeds);
speed_costs = 1;


% final greedy cost
%predicted_cost = -1e-1*sqrt(variance)*speed_costs.*length_weights./(match_costs+1);

% predicted_cost = cost * length_normalized_turn * punishment_factor
%predicted_cost = match_costs ./ (1:num_cols) .* length_weights;

predicted_cost = match_costs ./ (1:num_cols) ./ length_weights;

%pause
[greedy_cost, idx] = min( predicted_cost );
%-1e-1*sqrt(variance)*speed_costs.*length_weights./(match_costs+1)

%fprintf(' 1e-1 * %.2f * %.2f * %d^2.0 ./ %.2f =   %.2f \n', sqrt(variance), speed_costs(idx), lengths(idx), match_costs(idx)+1, greedy_cost);
%fprintf('      distance:  %.2f m, time: %.2f sec\n', dist, times(idx));
%fprintf('      avg_speed: %.2f m/s\n', avg_speeds(idx));

%pause

end















