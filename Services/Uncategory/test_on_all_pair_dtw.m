A = rand(1, 5);
B = rand(1, 10);

reA = zeros(10) * NaN;
for i = 1:10
    for j = i:10
        [~, ~, D] = dtw_baro(A, B(i:j));
        reA(i, j) = D(end, end);
    end
end

reB = all_pair_dtw_baro(A, B);

reA
reB

% test reuslt: match