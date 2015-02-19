% compute the similarity two rawPaths
function score = getPathSimilarity(pathA, pathB)

% score = (LCS * LCS) / (length(A) + length(B))
lenA = length(pathA);
lenB = length(pathB);
dp = zeros(lenA+1, lenB+1);
dp(1, 1) = 0;
for i = 1:lenA
    for j = 1:lenB
        dp(i+1, j+1) = max( [ dp(i,j+1) dp(i+1, j) (dp(i,j) + (pathA(i)==pathB(j))) ] );
    end
end
lcs = dp(end, end);
score = lcs * lcs / lenA / lenB;

end
