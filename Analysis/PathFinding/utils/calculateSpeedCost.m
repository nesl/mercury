function [ costs ] = calculateSpeedCost( speeds_mps )
% calculate the cost of going a certain speed, assuming typical average
% speed is between 10 and 60 mph.

speed_min = 5; % m/s
speed_max = 25; % m/s
penalty = 1.5;

costs = ones(size(speeds_mps));

for i=1:length(costs)
    speed = speeds_mps(i);
    
    if speed < 0
        cost = inf;
    elseif speed < speed_min
        cost = ( (1/10)*(speed_min - speed) )^penalty;
    elseif speed < speed_max
        cost = 0;
    else
        cost = ( (1/10)*(speed - speed_max) )^penalty;
    end
    
    % add on top of one so it can be multiplied
    cost = cost + 1;
    
    costs(i) = cost;
    
end

end

