%% Housekeeping
clc; close all; clear all;

%% Fake signals
t = 0:0.05:10;
s1 = sin(t).^2 + 2*cos(0.5*t + 0.2);
s2 = -cos(t) - sin(0.2*t) - t + 0.1*t.^2 - 3;

%% Partial DTW
L_arr = [];
c2_arr = [];
c1_arr = [];


for L = 10:5:200
    p1 = s1(1:L);
    p1 = p1 + 0.05*randn(size(p1)) - 0;
    p1 = imresize(p1, [1 round(L*1.5)]);
    p2 = 5+ s2(1:L);
    p2 = p2 + 0.05*randn(size(p2));
    p2 = imresize(p2, [1 round(L*1.5)]);
    
%     plot(s1);
%     hold on;
%     plot(p1,'r','LineWidth',3);
%     plot(p2,'m--','LineWidth',2);
%     hold off;
%     figure()
        
    c2 = DTW_greedy(s1,p2);
    c1 = DTW_greedy(s1,p1);
    % plot(c1(end,:),'r');
    % hold on;
    % plot(c2(end,:),'m');
    
    c2_arr = [c2_arr; c2];
    c1_arr = [c1_arr; c1];
    L_arr = [L_arr; L];
end

plot(L_arr, c1_arr, 'r');
hold on;
plot(L_arr, c2_arr, 'm--');