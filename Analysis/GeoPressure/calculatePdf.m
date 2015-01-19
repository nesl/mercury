function [ centers, normalized_sums ] = calculatePdf( x, bins )
% CALCULATEPDF:
% [centers, prob] = calculatePdf( input, # bins)
%

centers = [];
sums = [];

start = min(x);
stop = max(x);
delta = (stop-start)/bins;

for i=start:delta:stop
    % window
    w_start = i;
    w_stop = i+delta;
    w_center = w_start + (delta/2);
    
    
    this_sum = length(find(x > w_start & x < w_stop));
   
    centers = [centers;
        w_center];
    sums = [sums;
        this_sum];
end

% normalize sums
normalized_sums = sums./(sum(sums));

end

