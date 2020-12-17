% This file is part of the PLATT reference implementation
% Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)

close all
clear
clc

graphics_toolkit qt;

addpath ../../tools;

% Load the configuration (edit configuration.m)
configuration

% Set the configuration (edit set_configuration.m)
set_configuration

% The C code is written to work in a realtime implementation where no memory
% can be alloctaed. Hence, we need to "prepare" all the memory in advance

% State of the Gammatone filters (real and imaginary part)
state = zeros(2*ORDER*NUMFILTERS,1,'single'); 
% Buffer for filtered signals (real and imaginary part)
buffer = zeros(2*TICKSIZE*NUMFILTERS,1,'single');
% Amplitude maxima
maxima = zeros(NUMFILTERS,1,'single');
% Age of last maximum value
age = zeros(NUMFILTERS,1,'single');
% Frequency dependent gains
gain = zeros(NUMFILTERS,1,'single');
% Buffer for calculating layers (current and last sample)
layerbuffer = zeros(2*NUMLAYERS*NUMFILTERS,1,'single');
% Layer values
layers = zeros(NUMLAYERS*NUMFILTERS,1,'single');
% Differences between adjacent layers
differences = zeros((NUMLAYERS-1)*NUMFILTERS,1,'single');
% Target maximum amplitudes
target = zeros(NUMFILTERS,1,'single');
% Buffer for approximate amplitude maxima on basilar membrane
% by considerung transmission loss
transmissionbuffer = zeros(NUMFILTERS,1,'single');
% Buffer for specrtal operations (e.g., convolution or masking)
spectralbuffer = zeros(NUMFILTERS,1,'single');
% Compression factors (re-used for each layer)
compression = zeros(NUMFILTERS,1,'single');
% Buffer for calculating compression factors
compressionbuffer = zeros(NUMFILTERS,1,'single');
% Output samples
out = zeros(TICKSAMPLES,1,'single');

% Generate some signal with dynamics
duration = 2; % seconds

% Frequency-amplitude sweep
amplitude_start = 20-130; % dB FS
amplitude_stop = 110-130; % dB FS
freq_start = 100; % Hz
freq_stop = 10000; % Hz
phase_diff_start = 2.*pi.*freq_start./fs;
phase_diff_stop = 2.*pi.*freq_stop./fs;
phase = cumsum(logspace(log10(phase_diff_start), log10(phase_diff_stop), round(fs.*duration)));
signal_sweep1 = 10.^(linspace(amplitude_start,amplitude_stop,round(fs.*duration))./20).*sin(phase);

freq_start = 1000;
freq_stop = 1000;
amplitude_start = 65-130; % dB FS
amplitude_stop = 65-130; % dB FS
phase_diff_start = 2.*pi.*freq_start./fs;
phase_diff_stop = 2.*pi.*freq_stop./fs;
phase = cumsum(logspace(log10(phase_diff_start), log10(phase_diff_stop), round(fs.*duration)));
signal_sweep2 = 10.^(linspace(amplitude_start,amplitude_stop,round(fs.*duration))./20).*sin(phase);
signal_in = signal_sweep1 + signal_sweep2;


% IMPORTANT! Signal must be column vector!
signal_in = signal_in(:);
duration = size(signal_in,1)./fs;

% Calculate number of ticks
numticks = floor(duration.*fs./TICKSAMPLES-1);

% Memory to store the history of some variables 
% Signal samples (to have the full processed signal available)
signal_out = zeros(size(signal_in));
% Maxima at each tick (from "log Mel-Gammatone Maximogram")
% I wanted to use this representation for years!
maxima_hist = zeros(NUMFILTERS,numticks,'single');
% Age (in ticks) of the last maximum
age_hist = zeros(NUMFILTERS,numticks,'single');
% Values of all layers for each tick
layers_hist = zeros(NUMLAYERS*NUMFILTERS,numticks,'single');
% Values of differences between adjacent layers for each tick
differences_hist = zeros((NUMLAYERS-1)*NUMFILTERS,numticks,'single');
% The mapped base for each tick
base_hist = zeros(NUMFILTERS,numticks,'single');
% The compression coefficients for each difference
compression_hist = zeros((NUMLAYERS-1)*NUMFILTERS,numticks,'single');
% The target maximum amplitudes after adding each layer for each tick
target_hist = zeros(7*NUMFILTERS,numticks,'single');
% The resulting gains after adding each layer and for each tick
gain_hist = zeros(8*NUMFILTERS,numticks,'single');

% A loop that calculates the updates tick after tick (just like in the realtime variant)
tic;
for i=1:numticks

  % Get the next samples from the input signal
  in = single(signal_in(1+(i-1)*TICKSAMPLES:i*TICKSAMPLES));
  
  % Perform the combined gammatone filter and and maximum tracking
  % This function performs the filtering with each of the Gammatone filters,
  % tracks the maximum amplitudes, and applies the input calibration.
  % The tracking holds each maximum 15 ms (MAXHOLDTICKS) and then decreases it 
  % by 1 dB per ms (MAXDECAY)
  [~, ... coeff
   ~, ... calibration
   ~, ... thresholds_normal
   ~, ... in
   state, ...
   buffer, ...
   maxima, ...
   age] = gammatonemax_wrapper(coeff, ... 
                               calibration, ... 
                               thresholds_normal, ... 
                               in, ... 
                               state, ... 
                               buffer, ... 
                               maxima, ... 
                               age);
  % Store the output for a spectrogram-like representation
  maxima_hist(:,i) = maxima;
  % Store age for an overview when updates to the maxima happen
  age_hist(:,i) = age;
  
  % Calulcate the layers
  for j=0:5
    % Layer number
    layer = int32(j);
    % The layers are calculated by combining spectral convolution of the maxima with
    % hanning windows of increasing width and the (temporal) difference 
    % from the current and the last sample (temporal modulations)
    % In other words, specral low pass filtering and a temporal derivative (also
    % a low pass)
     [~, ... maxima
      layerbuffer(1+j*2*NUMFILTERS:(j+1)*2*NUMFILTERS), ...
      layers(1+j*NUMFILTERS:(j+1)*NUMFILTERS)] = ...
      calculatelayers_wrapper(maxima, ...
                           layerbuffer(1+j*2*NUMFILTERS:(j+1)*2*NUMFILTERS), ...
                           layers(1+j*NUMFILTERS:(j+1)*NUMFILTERS), ...
                           layer);
  end
  % Store values of all layers
  layers_hist(:,i) = layers;

  % Calculate the differences between adjacent layers
  % This achives band-pass filtered versions of the maxima
  % All band-pass filtered versions add up to the original maxima
  for j=0:4
   layers_ref = layers(1+j*NUMFILTERS:(j+1)*NUMFILTERS);
   layers_diff = layers(1+(j+1)*NUMFILTERS:(j+2)*NUMFILTERS);
   [~, ... layers_ref
    ~, ... layers_diff
    differences(1+j*NUMFILTERS:(j+1)*NUMFILTERS)] = ...
    calculatedifferences_wrapper(layers_ref, ...
                                 layers_diff, ...
                                 differences(1+j*NUMFILTERS:(j+1)*NUMFILTERS));
  end
  % Store values of all differences
  differences_hist(:,i) = differences;

  % The base layer is the one with the lowest spectral modulations that has no
  % further adjacent layer to calculate a difference
  base = layers(1+5*NUMFILTERS:(5+1)*NUMFILTERS);
  
  % The base layer (working point for adding further dynamic) is mapped to 
  % an audible level range using the input output function and describes
  % the current target levels
  [~, ... base
   ~, ... io_left
   target] = mapbase_wrapper(base, ...
                            gt_left, ...
                            target);
  % Store base layer, the current target and the (theoretically) resulting gains
  base_hist(:,i) = base;
  target_hist(1:NUMFILTERS,i) = target;
  gain_hist(1:NUMFILTERS,i) = target - maxima;

  % Check that the target does not exceed the maximum levels and mute the 
  % marked channels
  [~, ... mute_left
   ~, ... maxlevel_left
   target] = checkmaxlevels_wrapper(mute_left, ...
                                    maxlevel_left, ...
                                    target);
  % Avoid spectral masking which can ocurr by high levels at other freqcuencies
  % Calculate the required additional gain to avoid spectral masking and apply it.
  % Here a possible transmission loss is taken into account
  [~, ... spectralmask
   ~, ... transmission_left
   ~, ... spectralbuffer
   ~, ... transmissionbuffer
   target] = spectralmasking_wrapper(spectralmask, ...
                                     transmission_left, ...
                                     spectralbuffer, ...
                                     transmissionbuffer, ...
                                     target);
  
  % Check again that levels are within the limits
  [~, ...
   ~, ...
   target] = checkmaxlevels_wrapper(mute_left, ...
                                    maxlevel_left, ...
                                    target);
                                    
  % Store target and corresponding gain values
  target_hist(1+NUMFILTERS:2*NUMFILTERS,i) = target;
  gain_hist(1+NUMFILTERS:2*NUMFILTERS,i) = target - maxima;
  
  % This is the heart of the algorithm
  % Add back the remaining dynamic in the differences (band-pass)
  % The first difference is added back inconditionally because it contains 
  %   fast changes from channel to channel which compromises quality
  % The second difference contains the most important speech dynamic
  %   It is added back inconditionally and optionally expanded 
  % The third difference contains very fast temporal changes (mostly onsets)
  %   which are preserved conditionally. The condition is that adding the dynamic
  %   the levels must neither exceed the defined maximum level nor the minimum level
  %   A violation of the condition is calculated and the corresponding minimum 
  %   affordable compression factor is calculated. This factor is propagated back
  %   to the neighboring channels in order to avoid the introduction of higher
  %   spectral modulations
  % The fourth and fifth differences are added in the same way. They contain 
  %   The remaining spectral dynamic
  % If all dynamic is added back uncomressed/extended the only compression 
  %   results from mapping the base layer
  % The approach aims to avoid compression and masking, which is the fundamental
  % conflict in hearing aids. Here, the applied compression "dynamically" depends 
  % on the dynamic of the input signal and the available target dynamic.
  % In other words, when no compression is needed no compression is applied.
  % If compression is required to avoid masking, then only the minimum to achive 
  % this is applied. The core speech dynamic (structures of 2-4 ERB) is never compressed.
  % The reaction time is 1ms.
  for j=0:4
    layer = int32(j);
    [~, ... difference
     ~, ... expansion
     ~, ... spectralbuffer
     compressionbuffer, ... compressionbuffer
     compression, ... compression
     ~, ... maxlevel
     ~, ... io
     target] = adddynamic_wrapper(differences(1+j*NUMFILTERS:(j+1)*NUMFILTERS),
                                  expansion_left,
                                  spectralbuffer,
                                  compressionbuffer,
                                  compression,
                                  maxlevel_left,
                                  io_left,
                                  target,
                                  layer);
    % Store compression, target, and gain after each layer to see the evolution
    compression_hist(1+(j)*NUMFILTERS:(j+1)*NUMFILTERS,i) = compression;
    target_hist(1+(j+2)*NUMFILTERS:(j+3)*NUMFILTERS,i) = target;
    gain_hist(1+(j+2)*NUMFILTERS:(j+3)*NUMFILTERS,i) = target - maxima;
  end
  
  % The reference levels to calculate the gains are the maximum amplitudes
  % of the input signal
  reference = maxima;
  % Resynthesis applies the gains to the output of the Gammatone filters
  % and adds the modified outputs up. The gains are only allowed the change
  % at a rate of 6 dB per period.
  [~, ... calibration
   ~, ... gainrate
   ~, ... buffer
   ~, ... reference
   ~, ... target
   gain, ... 
   out] = resynthesis_wrapper(calibration, ...
                             gainrate, ...
                             buffer, ...
                             reference, ...
                             target, ...
                             gain, ...
                             out);
  gain_hist(1+(7)*NUMFILTERS:(8)*NUMFILTERS,i) = gain;
  
  signal_out(1+(i-1)*TICKSAMPLES:i*TICKSAMPLES) = out;
end
t1 = toc;

% Write the signal to audifile so that you can listen to them
audiowrite('signal_in.wav',signal_in,fs,'BitsPerSample',32);
audiowrite('signal_out.wav',signal_out,fs,'BitsPerSample',32);


%% Test the C version of the loop (implemented in tick.c)
signal_in_ref1 = single(signal_in);
signal_in_ref2 = single(signal_in);
tic;
[signal_out_ref1, signal_out_ref2] = platt(signal_in_ref1, signal_in_ref2);
t2 = toc;
printf('The C version needs %.2fs to process %.2fs of a stereo real time signal...\n',t2,duration);
printf('...instead of %.2fs to process %.2fs of a mono real time signal\n',t1,duration);


%addpath /home/marc/fade/fade.d/features.d/standalone
%b = (log_mel_spectrogram(signal_out,fs));
%a = (log_mel_spectrogram(threshold_audiofile(1:length(signal_out),1),fs));
%imagesc((a<b).*a);
%sum((a<b)(:))
%break


%% FIGURES FIGURES FIGURES
% Now lets plot some figures

% Panorama plot of input signal waveform and log Mel-Gammatone Maximogram
figure('Position',[0 0 1600 800]);
subplot = @(m,n,p) axes('Position',subposition(m,n,p));
subplot(2,1,1);
plot((0:length(signal_in)-1).*1000./fs,signal_in);
axis tight;
set(gca,'XTick',0:100:round(duration*1000));
xlabel('Time / ms');
ylabel('Sound pressure');
title('Input waveform');
subplot(2,1,2);
imagesc(maxima_hist,[-10 100]);
axis xy;
set(gca,'XTick',0:100:numticks);
set(gca,'YTick',1:8:length(freqs));
set(gca,'YTickLabel',num2str(freqs(1:8:end).','%.0f'));
xlabel('Time / ms');
ylabel('Mel band center frequency / Hz');
text(0,72,'    Input log Mel-Gammatone Maximogram','color',[1 1 1],'fontsize',15);
colorbar('location', 'east');

% Panorama plot of the layers
figure('Position',[0 0 1600 800]);
subplot = @(m,n,p) axes('Position',subposition(m,n,p,[0.0 0.01],[],[]));
for i=1:6
  subplot(6,1,i);
  imagesc(layers_hist(1+(i-1)*NUMFILTERS:(i)*NUMFILTERS,:),[-10 100]);
  axis xy;
  set(gca,'XTick',0:100:numticks);
  set(gca,'XTickLabel',[]);
  set(gca,'YTick',1:8:length(freqs));
  set(gca,'YTickLabel',num2str(freqs(1:8:end).','%.0f'));
  ylabel('Frequency / Hz');
  colorbar('location', 'east');
  text(0,70,sprintf('   Layer %i',i),'color',[1 1 1],'fontsize',15);
end
set(gca,'XTickLabel',0:100:numticks);
xlabel('Time / ms');

% Panorama plot of the differences
figure('Position',[0 0 1600 800]);
subplot = @(m,n,p) axes('Position',subposition(m,n,p,[0.0 0.01],[],[]));
for i=1:5
  subplot(5,1,i);
  imagesc(differences_hist(1+(i-1)*NUMFILTERS:(i)*NUMFILTERS,:),[-20 20]);
  axis xy;
  set(gca,'XTick',0:100:numticks);
  set(gca,'XTickLabel',[]);
  set(gca,'YTick',1:8:length(freqs));
  set(gca,'YTickLabel',num2str(freqs(1:8:end).','%.0f'));
  ylabel('Frequency / Hz');
  colorbar('location', 'east');
  text(0,70,sprintf('   Difference: Layer %i - Layer %i',i,i+1),'color',[1 1 1],'fontsize',15);
end
set(gca,'XTickLabel',0:100:numticks);
xlabel('Time / ms');

% Panorama plot of the compression coefficients
figure('Position',[0 0 1600 800]);
subplot = @(m,n,p) axes('Position',subposition(m,n,p,[0.0 0.01],[],[]));
titles = {
  'Layer 3 - Layer 4 (temporal onsets)' ...
  'Layer 4 - Layer 5 (coarse spectral strutcures)' ...
  'Layer 5 - Layer 6 (spectral coloring)' ...
};
for i=1:3
  subplot(3,1,i);
  imagesc(compression_hist(1+(i+1)*NUMFILTERS:(i+2)*NUMFILTERS,:));
  axis xy;
  set(gca,'XTick',0:100:numticks);
  set(gca,'XTickLabel',[]);
  set(gca,'YTick',1:8:length(freqs));
  set(gca,'YTickLabel',num2str(freqs(1:8:end).','%.0f'));
  ylabel('Frequency / Hz');
  colorbar('location', 'east');
  text(0,70,sprintf('   Compression: %s',titles{i}),'color',[1 1 1],'fontsize',15);
end
set(gca,'XTickLabel',0:100:numticks);
xlabel('Time / ms');

% Panorama plot of the targets
figure('Position',[0 0 1600 800]);
subplot = @(m,n,p) axes('Position',subposition(m,n,p,[0.0 0.01],[],[]));
data_tmp = [base_hist; ...
            target_hist(1+(2-1)*NUMFILTERS:(7)*NUMFILTERS,:); ...
            ];
titles = {
  'Base layer (Layer 6)' ...
  'Mapped base layer with maxima and spectral masking' ...
  '+ Difference: Layer 1 - Layer 2 (highest spectral modulations)' ...
  '+ (Expanded) difference: Layer 2 - Layer 3 (2-4 ERB wide structures, e.g., speech dynamic)' ...
  '+ Conditionally compressed difference: Layer 3 - Layer 4 (temporal onsets)' ...
  '+ Conditionally compressed difference: Layer 4 - Layer 5 (coarse spectral strutcures)' ...
  '+ Conditionally compressed difference: Layer 5 - Layer 6 (spectral coloring)' ...
};
for i=1:7
  subplot(7,1,i);
  imagesc(data_tmp(1+(i-1)*NUMFILTERS:(i)*NUMFILTERS,:),[-10 100]);
  axis xy;
  set(gca,'XTick',0:100:numticks);
  set(gca,'XTickLabel',[]);
  set(gca,'YTick',1:8:length(freqs));
  set(gca,'YTickLabel',num2str(freqs(1:8:end).','%.0f'));
  ylabel('Frequency / Hz');
  colorbar('location', 'east');
  text(0,70,sprintf('   Target: %s',titles{i}),'color',[1 1 1],'fontsize',15);
end
set(gca,'XTickLabel',0:100:numticks);
xlabel('Time / ms');


% Panorama plot of the gains
figure('Position',[0 0 1600 800]);
subplot = @(m,n,p) axes('Position',subposition(m,n,p,[0.0 0.01],[],[]));
data_tmp = [base_hist-maxima_hist; ...
            gain_hist(1+(2-1)*NUMFILTERS:(8)*NUMFILTERS,:); ...
            ];
titles = {
  'Base layer (Layer 6)' ...
  'Mapped base layer with maxima and spectral masking' ...
  '+ Difference: Layer 1 - Layer 2 (highest spectral modulations)' ...
  '+ (Expanded) difference: Layer 2 - Layer 3 (2-4 ERB wide structures, e.g., speech dynamic)' ...
  '+ Conditionally compressed difference: Layer 3 - Layer 4 (temporal onsets)' ...
  '+ Conditionally compressed difference: Layer 4 - Layer 5 (coarse spectral strutcures)' ...
  '+ Conditionally compressed difference: Layer 5 - Layer 6 (spectral coloring)' ...
  'Final smoothed gains (to prevent side bands)' ...
};
for i=1:8
  subplot(8,1,i);
  imagesc(data_tmp(1+(i-1)*NUMFILTERS:(i)*NUMFILTERS,:),[-20 40]);
  axis xy;
  set(gca,'XTick',0:100:numticks);
  set(gca,'XTickLabel',[]);
  set(gca,'YTick',1:8:length(freqs));
  set(gca,'YTickLabel',num2str(freqs(1:8:end).','%.0f'));
  xlabel('Time / ms');
  ylabel('Frequency / Hz');
  colorbar('location', 'east');
  text(0,70,sprintf('   Gains: %s',titles{i}),'color',[1 1 1],'fontsize',15);
end
set(gca,'XTickLabel',0:100:numticks);
xlabel('Time / ms');


% Panorama plot of the compressed differences
figure('Position',[0 0 1600 800]);
subplot = @(m,n,p) axes('Position',subposition(m,n,p,[0.0 0.01],[],[]));
data_tmp = [base_hist-maxima_hist; ...
            gain_hist(1+(2-1)*NUMFILTERS:(8)*NUMFILTERS,:); ...
            ];
titles = {
  'Mapping of base layer' ...
  'Layer 1 - Layer 2 (highest spectral modulations)' ...
  'Layer 2 - Layer 3 (2-4 ERB wide structures, e.g., speech dynamic)' ...
  'Layer 3 - Layer 4 (temporal onsets)' ...
  'Layer 4 - Layer 5 (coarse spectral strutcures)' ...
  'Layer 5 - Layer 6 (spectral coloring)' ...
  'Final gain smoothing (to prevent side bands)' ...
};
for i=1:7
  subplot(7,1,i);
  imagesc(data_tmp(1+(i)*NUMFILTERS:(i+1)*NUMFILTERS,:)-data_tmp(1+(i-1)*NUMFILTERS:(i)*NUMFILTERS,:),[-20 20]);
  axis xy;
  set(gca,'XTick',0:100:numticks);
  set(gca,'XTickLabel',[]);
  set(gca,'YTick',1:8:length(freqs));
  set(gca,'YTickLabel',num2str(freqs(1:8:end).','%.0f'));
  xlabel('Time / ms');
  ylabel('Frequency / Hz');
  colorbar('location', 'east');
  text(0,70,sprintf('   Compressed differences: %s',titles{i}),'color',[1 1 1],'fontsize',15);
end
set(gca,'XTickLabel',0:100:numticks);
xlabel('Time / ms');


% Panorama plot maxima (input), target, and final gains
figure('Position',[0 0 1600 800]);
subplot = @(m,n,p) axes('Position',subposition(m,n,p));
subplot(5,1,1);
plot((0:length(signal_in)-1).*1000./fs,signal_in);
set(gca,'XTick',0:100:round(duration*1000));
axis tight;
xlabel('Time / ms');
ylabel('Sound pressure');
title('Input waveform');
subplot(5,1,2);
imagesc(maxima_hist,[-10 100]);
axis xy;
set(gca,'XTick',0:100:numticks);
set(gca,'YTick',1:8:length(freqs));
set(gca,'YTickLabel',num2str(freqs(1:8:end).','%.0f'));
xlabel('Time / ms');
ylabel('Frequency / Hz');
colorbar('location', 'east');
text(0,70,'   Input maxima','color',[1 1 1],'fontsize',15);
subplot(5,1,3);
imagesc(target_hist(end-NUMFILTERS:end,:),[-10 100]);
axis xy;
set(gca,'XTick',0:100:numticks);
set(gca,'YTick',1:8:length(freqs));
set(gca,'YTickLabel',num2str(freqs(1:8:end).','%.0f'));
xlabel('Time / ms');
ylabel('Frequency / Hz');
colorbar('location', 'east');
text(0,70,'   Target maxima','color',[1 1 1],'fontsize',15);
subplot(5,1,4);
imagesc(gain_hist(end-NUMFILTERS:end,:),[-20 40]);
axis xy;
set(gca,'XTick',0:100:numticks);
set(gca,'YTick',1:8:length(freqs));
set(gca,'YTickLabel',num2str(freqs(1:8:end).','%.0f'));
xlabel('Time / ms');
ylabel('Frequency / Hz');
colorbar('location', 'east');
text(0,70,'   Gains','color',[1 1 1],'fontsize',15);
subplot(5,1,5);
plot((0:length(signal_out)-1).*1000./fs,signal_out);
set(gca,'XTick',0:100:round(duration*1000));
axis tight;
xlabel('Time / ms');
ylabel('Sound pressure');
title('Output waveform');

% Analysis of input-output at a certain frames 
t_inspect = [500];

legend_string = { ...
  'Normal hearing threshold' ...
  'Input low' ...
  'Input high' ...
  'Output low' ...
  'Output high' ...
  'Individual hearing threshold' ...
  'Indivudial uncomfortable level' ...
  'Input maxima' ...
  'Input base' ...
  'Target base' ...
  'Target essential' ...
  'Target quality' ...
  'Target final' ...
};
h = [];
for t=t_inspect
  figure('Position',[0 0 1600 800]);
  h(1) = plot(log(freqs),thresh_nh,':k','Linewidth',2);
  set(gca,'XTick',log([125 250 500 1000 2000 4000 8000 16000]));
  set(gca,'XTickLabel',[125 250 500 1000 2000 4000 8000 16000]);
  set(gca,'YTick',0:10:110);
  xlim(log([100 20000]));
  ylim([-10 120]);
  hold on;
  h(2) = plot(log(freqs),level_in_low1,'--','color',[0.9 0 0],'Linewidth',2);
  h(3) = plot(log(freqs),level_in_high1,'--','color',[0 0.8 0],'Linewidth',2);
  h(4) = plot(log(freqs),level_out_low1,'-','color',[0.9 0 0],'Linewidth',2);
  h(5) = plot(log(freqs),level_out_high1,'-','color',[0 0.8 0],'Linewidth',2);
  h(6) = plot(log(freqs),thresh1,'^k');
  h(7) = plot(log(freqs),uncomf1,'vk');
  h(8) = plot(log(freqs),maxima_hist(:,t),'--','color',[1 0.5 0],'LineWidth',2);
  h(9) = plot(log(freqs),base_hist(:,t),'--','color',[0 0.5 1],'LineWidth',2);
  i=2;
  h(10) = plot(log(freqs), target_hist(1+(i-1)*NUMFILTERS:(i)*NUMFILTERS,t),'-','color',[0 0.5 1],'LineWidth',2);
  i=3;
  h(11) = plot(log(freqs), target_hist(1+(i-1)*NUMFILTERS:(i)*NUMFILTERS,t),'-','color',[0.5 0.5 1],'LineWidth',2);
  i=4;
  plot(log(freqs), target_hist(1+(i-1)*NUMFILTERS:(i)*NUMFILTERS,t),'-','color',[0.5 0.5 1],'LineWidth',2);
  i=5;
  h(12) = plot(log(freqs), target_hist(1+(i-1)*NUMFILTERS:(i)*NUMFILTERS,t),':','color',[1 0.5 0.5],'LineWidth',2);
  i=6;
  plot(log(freqs), target_hist(1+(i-1)*NUMFILTERS:(i)*NUMFILTERS,t),':','color',[1 0.5 0.5],'LineWidth',2);
  i=7;
  h(13) = plot(log(freqs), target_hist(1+(i-1)*NUMFILTERS:(i)*NUMFILTERS,t),'-','color',[1 0.5 0],'LineWidth',2);
  title(sprintf('Frame %i',t));
  xlabel('Frequency / Hz');
  ylabel('Amplitude / dB SPL');
  legend(h,legend_string);
end      

