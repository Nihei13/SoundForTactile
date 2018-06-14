clear all;
close all;

fs = 44100;

NumLength = 1; %Secs

t = [0:1/fs:NumLength];

f1 = 100;

y1 = sin(2*pi*f1*t);

f2 = 20;

y2 = (square(2*pi*f2*t)+1)/2;

% soundsc(y1, fs);

figure
plot(t, y1);

figure
plot(t, y2);

figure
plot(t, y1.*y2);

soundsc(y1.*y2, fs);
