%% Housekeeping
clc; close all; clear all;

%% Fake signals
t = 0:0.05:10;
s1 = sin(t).^2 + 2*cos(0.5*t + 0.2);
s2 = -cos(t) - sin(0.2*t) - t + 0.1*t.^2 - 3;

%% Partial DTW
p1 = s1(1:40);
p1 = p1 + 0.05*randn(size(p1)) - 0.5;
p1 = imresize(p1, [1 80]);
p2 = 5+ s2(1:40);
p2 = p2 + 0.05*randn(size(p2));

plot(s1);
hold on;
plot(p1,'r','LineWidth',3);
plot(p2,'m--','LineWidth',2);
hold off;
figure()

c2 = DTW_greedy(s1,p2);
c1 = DTW_greedy(s1,p1);
plot(c1(end,:),'r');
hold on;
plot(c2(end,:),'m');