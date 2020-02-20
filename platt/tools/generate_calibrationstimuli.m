#!/usr/bin/octave
close all;
clear;
clc;

fs = 48000; % Hz
targetlevel = 80; % dB SPL
duration = 6; % s

signal = randn(duration.*fs,1);

[signal_filtered, centers, filters] = mel_gammatone_iir(signal, fs);
mkdir('calibrationstimuli');
for i=1:length(centers)
  signal = real(signal_filtered(:,i));
  signal = signal./sqrt(mean(signal.^2)).*10.^((targetlevel-130)./20);
  rms = 20*log10(sqrt(mean(signal.^2)))+130;
  audiowrite(sprintf("calibrationstimuli/%.1fHz_%.1fdBSPL_noise.wav",centers(i),rms),signal,fs,'BitsPerSample',32);
end
