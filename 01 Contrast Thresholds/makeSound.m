
amp = [0.5 0.2 0.2 0.1];
fs= 20500;  % sampling frequency
durS = 0.025;
freqHz = [250 1000 2000 4000];
values = 0:1/fs:durS;

for i = 1:length(amp)
    a = amp(i) * sin(2 * pi * freqHz(i) * values);
    sound(a);
    pause(0.5);
    filename = sprintf('Tone%4d.wav', freqHz(i))
    audiowrite(filename,a, fs);
end