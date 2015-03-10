load ../../Data/tmpMatFiles/sens.mat

%"baseline": one minute, outside.
%"outside": one minute, outside.
%"inside_engiv": three minute, inside ENG IV, 6th floor.
%"inside_nesl": one minute, inside NESL.

cfigure(14, 6)

outSideLength = 50;
baro = zeros(4, 50);
for i = 1:4
    for j = 1:50
        idx = ( ceil(inside_engiv{i}(:,1)) == j );
        baro(i, j) = mean(inside_engiv{i}(idx,2));
    end
end

clf
hold on
plot(1:50, baro(1,:)-baro(1,1), '-ro', 'LineWidth', 2, 'MarkerSize', 6);
plot(1:50, baro(2,:)-baro(1,1), '-g^', 'LineWidth', 2, 'MarkerSize', 6);
plot(1:50, baro(3,:)-baro(1,1), '-b*', 'LineWidth', 2, 'MarkerSize', 6);
plot(1:50, baro(4,:)-baro(1,1), '-mv', 'LineWidth', 2, 'MarkerSize', 6);
xlabel('Time (sec)', 'FontSize', 14)
ylabel('Pressure (hPa)', 'FontSize', 14);
ylim([-0.2 0.1])
legend({'h=0', 'h=10', 'h=20', 'h=30 cm'}, 'Location', 'north', 'Orientation', 'horizontal')
grid on

saveplot('~/Dropbox/MercuryWriting/mobicom15/figs/barometer_sensing_ability')

return

%%
for i = 1:4
    max(outside{i}(:,1))
    min(outside{i}(:,1))
end