A = rand(1, 10) * 10;
B = rand(1, 10) * 10;

clf
hold on

off = [
    -1 -1
    -1  0
     0 -1
];


[D, P] = dtw_path_matrix(A, B);
Pa = P;
for i = 1:10
    for j = 1:10
        p = P(i, j);
        plot([i i+off(p, 1)], [j j+off(p, 2)], 'b-')
    end
end

[D, P] = dtw_path_matrix(A(2:end), B);
Pb = P;
for i = 1:9
    for j = 1:10
        p = P(i, j);
        plot([i i+off(p, 1)]+1.1, [j j+off(p, 2)]+0.05, 'r-')
        if Pa(i+1, j) ~= Pb(i,j)
            plot(i+1, j, 'ko', 'MarkerSize', 10)
        end
    end
end

% this script test on the following problem: suppose I have any result or
% intermediate result of DTW(A, B), can I calculate DTW( A(2:end), B )
% based on the intermediate results from previous step? currently I cannot
% find and conclusion...
%
% some observation which may be useful:
% - a point can come from west (1), south-west (2), and south (3). this 
%   then the first element of A is removed, meaning that the path matrix is
%   removed one column, the source of each point will remain or get from
%   the source with higher index.