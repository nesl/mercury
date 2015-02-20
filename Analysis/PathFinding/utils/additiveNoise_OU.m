function [ noise ] = additiveNoise_OU( times, rev_time, variance)
% Ohnstein-Uhlenbeck additive noise model for barometric sensor

r = rev_time;       % Reversion time (O-U)
m = 0;              % Mean (O-U, Gaussian, Wiener)
x = m;              % Starting estimate (O-U, Wiener)
v = variance;       % Variance (O-U, Wiener, Gaussian)
T = times(end) - times(1);    % Time
N = length(times);   % Epochs
d = T/N;    % deltaT

% For storing error trace
noise = zeros(1,N);

% Ornstein-Uhlenbeck
noise(1) = x;
for i = 2:N
    k = exp(-d/r);
    noise(i) = k*noise(i-1) + (1-k)*m + sqrt(v*(1-k*k)*r/2) * randn();
end

end

