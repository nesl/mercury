% each row is a test case
%
% first number is the score with correct path, rest (i.e, start from index
% 2) are sorted scores of other paths.

nums = csvread('/home/timestring/forBuildsys15/output.csv');

for i = 1:29
    nums(i, 2:end) = nums(i, 2:end) / nums(i, 1);
end

maxScore = max( nums(:, 2:end) );
minScore = min( nums(:, 2:end) );

nums = log10(nums);
boxplot(nums(:,2:end))