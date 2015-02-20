r = 10;     % Reversion time (O-U)
m = 10;     % Mean (O-U, Gaussian, Wiener)
x = m;      % Starting estimate (O-U, Wiener)
v = 2;      % Variance (O-U, Wiener, Gaussian)
T = 100;    % Time
d = T/N;    % deltaT
M = 1;   % Samples

% For storing sample traces
s_o = zeros(1,N);


% Ornstein-Uhlenbeck
s_o(1) = x;
for i = 2:N
    k = exp(-d/r);
    s_o(i) = k*s_o(i-1) + (1-k)*m + sqrt(v*(1-k*k)*r/2) * randn();
end
c(j) = s_o(end);
k = exp(-T/r);

disp('ORNSTEIN-UHLENBECK PROCESS');
disp('*********************************');
disp('Measured vs analytic mean:');
[mean(c) m+(x-m)*k]
disp('Measured vs analytic deviation:');
[var(c)  v*r/2*(1-k*k)]

hold on; grid on;
plot(s_o,'b-');
legend('Ornstein-Uhlenbeck');