N = 10000;

tic
a = zeros(N);
for i = 1:N
    a(i, 1:i) = 1:i;
end
toc

tic
b = cell(N, 1);
for i = 1:N
    b{i} = 1:i;
end
toc

whos('a')
whos('b')

Q = 100000;
idx = rand(Q, 2);
idx(:,1) = ceil(idx(:,1) * N);
idx(:,2) = ceil(idx(:,2) .* idx(:,1));

tic
sum = 0;
for i = 1:Q
    sum = sum + a( idx(i,1), idx(i,2) );
end
sum
toc

tic
sum = 0;
for i = 1:Q
    sum = sum + b{ idx(i,1) }( idx(i,2) );
end
sum
toc


% RESULT:  (N = 10000, Q = 100000)

%  Elapsed time is 0.815225 seconds.
%  Elapsed time is 0.052559 seconds.
%   Name          Size                   Bytes  Class     Attributes
% 
%   a         10000x10000            800000000  double              
% 
%   Name          Size                Bytes  Class    Attributes
% 
%   b         10000x1             401160000  cell               
% 
% 
% sum =
% 
%    249774747
% 
% Elapsed time is 0.084571 seconds.
% 
% sum =
% 
%    249774747
% 
% Elapsed time is 0.352241 seconds.


% CONCLUSION:
%   in terms of creation, cell is an order faster than array.
%   in terms of accession, array is 4x faster
%   under the assumption that th access ratio is 100%, array is better choice.