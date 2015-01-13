dir = '../../Data/eleSegments/ucla_west/';

% case 1 ground
p = [
343301146
122624759
123396586
122584789
496202094
496202095
122914625
122914624
122914622
566568258
];

datat = [];
for i = 1:(size(p,1)-1)
    if p(i) < p(i+1)
        name = [ int2str(p(i)) '_' int2str(p(i+1)) ];
    else
        name = [ int2str(p(i+1)) '_' int2str(p(i)) ];
    end
    data = csvread([dir name]);
    if p(i) > p(i+1)
        data = flipud(data);
    end
    size(data)
    
    %subplot(5, 1, i)
    plot(data)
    datat = [datat; data];
end
%subplot(5, 1, 4)
plot(datat)

dlmwrite('../../Data/eleSegments/test_case/case1_ac.csv', datat, 'delimiter', ',', 'precision', 9);