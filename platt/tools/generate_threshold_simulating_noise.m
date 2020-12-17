#!/usr/bin/octave -q
close all
clear
clc

fs = 48000;
duration = 60;
repetitions = 5;
reference = 130;

cfg_freqs       = [125    250    375    500    750   1000   1500   2000   3000   4000   6000   8000];
% hl = 40+zeros(size(f)); ht = ff2ed(f,hl2spl(f,hl));
cfg_threshold1  = [61   51   47   46   45   45   48   50   49   49   51   53];
cfg_threshold2  = [61   51   47   46   45   45   48   50   49   49   51   53];

cfg_freqs       = [0 cfg_freqs 24000];
cfg_threshold1 = cfg_threshold1([1 1:end end]);
cfg_threshold2 = cfg_threshold2([1 1:end end]);

freq_range = [64 16000];
supersample = 2;
qcontrol = 2;

% Get correction factor
printf('Calculate the gain correction factor\n');
whitenoise = randn(round(fs.*10),1);
[whitenoise_filtered, centers, filters] = mel_gammatone_iir(whitenoise, fs, freq_range, supersample, qcontrol);
whitenoise_filtered = sum(real(whitenoise_filtered),2);
[whitenoise_refiltered, centers, filters] = mel_gammatone_iir(whitenoise_filtered, fs, freq_range, supersample, qcontrol);
whitenoise_refiltered = sum(real(whitenoise_refiltered),2);

whitenoise_filtered_rms = sqrt(mean(whitenoise_filtered(round(0.1*fs):end-round(0.1*fs),:).^2));
whitenoise_refiltered_rms = sqrt(mean(whitenoise_refiltered(round(0.1*fs):end-round(0.1*fs),:).^2));

% cf. GAINCORRECTION in constanst.h which should be equal to 20*log10(correction_factor)
correction_factor = whitenoise_filtered_rms./whitenoise_refiltered_rms;

printf('Generate left channel noise\n');
whitenoise = randn(round(fs.*(duration+0.1)),60);
whitenoise_filtered = mel_gammatone_iir(whitenoise, fs, freq_range, supersample, qcontrol);
whitenoise_filtered = real(whitenoise_filtered);
whitenoise_filtered_rms = sqrt(mean(real(whitenoise_filtered).^2));
target_levels_left_db = interp1(cfg_freqs, cfg_threshold1, centers);
target_levels_left = 10.^((target_levels_left_db-reference)./20);
left_noise = correction_factor .* sum(whitenoise_filtered .* (target_levels_left ./ whitenoise_filtered_rms),2);

left_check = mel_gammatone_iir(left_noise, fs, freq_range, supersample, qcontrol);
left_check = real(left_check);
left_check_rms = sqrt(mean(real(left_check).^2));

printf('Generate right channel noise\n');
whitenoise = randn(round(fs.*(duration+0.1)),60);
whitenoise_filtered = mel_gammatone_iir(whitenoise, fs, freq_range, supersample, qcontrol);
whitenoise_filtered = real(whitenoise_filtered);
whitenoise_filtered_rms = sqrt(mean(real(whitenoise_filtered).^2));
target_levels_right_db = interp1(cfg_freqs, cfg_threshold2, centers);
target_levels_right = 10.^((target_levels_right_db-reference)./20);
right_noise = correction_factor .* sum(whitenoise_filtered .* (target_levels_right ./ whitenoise_filtered_rms),2);

right_check = mel_gammatone_iir(right_noise, fs, freq_range, supersample, qcontrol);
right_check = real(right_check);
right_check_rms = sqrt(mean(real(right_check).^2));

% Use this code to visualize the achieved thresholds
figure;
subplot(1,2,1);
h=[];
h(1) = plot(centers,20*log10(target_levels_left)+reference);
hold on;
h(2) = plot(centers,20*log10(left_check_rms)+reference);
ylim([-20 100]);
xlabel('Frequency / Hz');
ylabel('Threshold / dB SPL');
legend(h, {'Target RMS', 'Actual RMS'});
subplot(1,2,2);
h=[];
h(1) = plot(centers,20*log10(target_levels_right)+reference);
hold on;
h(2) = plot(centers,20*log10(right_check_rms)+reference);
ylim([-20 100]);
xlabel('Frequency / Hz');
ylabel('Threshold / dB SPL');
legend(h, {'Target RMS', 'Actual RMS'});

threshold_simulating_noise = [left_noise(1+round(0.1*fs):end), right_noise(1+round(0.1*fs):end)];

printf('Repeat noise %i times\n',repetitions);

threshold_simulating_noise_repeated = threshold_simulating_noise;

% Extend duration by crossfade looping
crossover = round(0.25.*fs);
for i=1:repetitions
  threshold_simulating_noise_repeated = [threshold_simulating_noise_repeated(1:end-crossover,:); ...
                     threshold_simulating_noise_repeated(end-crossover+1:end,:).*sqrt(linspace(1,0,crossover)).' + ...
                     threshold_simulating_noise(1:crossover,:).*sqrt(linspace(0,1,crossover)).';
                     threshold_simulating_noise(crossover+1:end,:)];
end

printf('Write samples to: thresholdsimulation/thresholdsimulatingnoise.wav\n');
mkdir('thresholdsimulation');
audiowrite('thresholdsimulation/thresholdsimulatingnoise.wav',threshold_simulating_noise_repeated,fs,'BitsPerSample',32);
printf('done\n');

