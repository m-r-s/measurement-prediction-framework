#!/usr/bin/octave
close all
clear
clc

sourcedir = 'source';
targetdir = 'data/matrix';

% Define signal properties
fs = 44100;
referencelevel = 130; % dB SPL
referencechannel = 1;
targetlevel = 65; % dB SPL
maskerlength = 120; % seconds

% Define hrirs to use
hrir_speech = {[sourcedir filesep 'hrir' filesep 'cafeteria' filesep 'cafeteria_1_A.wav']};
delays_speech = 0.000; % s
gains_speech = 0; % dB

hrir_masker = {[sourcedir filesep 'hrir' filesep 'cafeteria' filesep 'cafeteria_1_C.wav']};
delays_masker = 0.000; % s
gains_masker = 0; % dB

function out = audioread_cell(in, fs0, channels)
  if nargin < 2
    fs0 = [];
  end
  if nargin < 2
    channels = [];
  end
  out = cell(size(in));
  assert(iscell(in))
  for i=1:length(in)
    [signal, fs] = audioread(in{i});
    if ~isempty(channels)
      signal = signal(:,channels);
    end
    if ~isempty(fs0) && fs ~= fs0
      signal = resample(signal, fs0, fs);
    end
    out{i} = signal;
  end
end

function signal = crossfade_extend(signal, crossfade, len)
  while (size(signal,1) < len)
    fade = repmat(linspace(0,1,crossfade).',1,size(signal,2));
    signal = [ ...
      signal(1:end-crossfade,:); ...
      signal(1:crossfade,:).* sqrt(fade) + ...
      signal(end-crossfade+1:end,:) .* sqrt(1-fade); ...
      signal(crossfade:end,:) ...
      ];
  end
end

function out = mix(in, irs, delays, gains)
  assert(iscell(irs));
  assert(size(in,2) == 1);
  if nargin < 3 || isempty(delays)
    delays = zeros(size(irs));
  end
  if nargin < 4 || isempty(gains)
    gains = zeros(size(irs));
  end
  filtered = cell(size(irs));
  for i=1:length(irs)
    ir = irs{i};
    ir = [zeros(size(ir));ir];
    filtered_tmp = zeros(size(in,1),size(ir,2));
    for j=1:size(ir,2)
      filtered_tmp(:,j) = real(fftconv2(in,ir(:,j), 'same'));   
    end
    filtered{i} = shift(filtered_tmp,delays(i)) .* 10.^(gains(i)./20);
  end
  if numel(filtered) > 1
    out = plus(filtered{:});
  else
    out = filtered{1};
  end
end

function out = fftconv2(in1, in2, shape)
  % 2D convolution in terms of the 2D FFT that substitutes conv2(in1, in2, shape).
  size_y = size(in1,1)+size(in2,1)-1;
  size_x = size(in1,2)+size(in2,2)-1;
  fft_size_x = 2.^ceil(log2(size_x));
  fft_size_y = 2.^ceil(log2(size_y));
  in1_fft = fft2(in1,fft_size_y,fft_size_x);
  in2_fft = fft2(in2,fft_size_y,fft_size_x);
  out_fft = in1_fft .* in2_fft;
  out_padd = ifft2(out_fft);
  out_padd = out_padd(1:size_y,1:size_x);
  switch shape
    case 'same'
      y_offset = floor(size(in2,1)/2);
      x_offset = floor(size(in2,2)/2);
      out = out_padd(1+y_offset:size(in1,1)+y_offset,1+x_offset:size(in1,2)+x_offset);
    case 'full'
      out = out_padd;
  end
end

% Select left in-ear (1) and front (3) center (5) and back (7) BTE
hrir_speech = audioread_cell(hrir_speech, fs, [1 3 5 7]);
hrir_masker = audioread_cell(hrir_masker, fs, [1 3 5 7]);

% Load microphone noise
pinknoise = audioread_cell({[sourcedir filesep 'noise' filesep 'pinknoise.wav']}, fs, [1 2 3 4]);
pinknoise = pinknoise{1};
pinknoise = crossfade_extend(pinknoise, round(fs.*0.25), round(fs.*(maskerlength+10)));

% Create dirs
mkdir(targetdir);
mkdir([targetdir filesep 'speech' filesep 'default']);
mkdir([targetdir filesep 'maskers']);

% Load test specific noise to calibrate speech level to 65 dB SPL in ear
tsn = audioread_cell({[sourcedir filesep 'maskers' filesep 'tsn.wav']}, fs, 1);
tsn = tsn{1};
tsn = crossfade_extend(tsn, round(fs.*0.25), round(fs.*(maskerlength+10)));
tsn_filtered = mix(tsn, hrir_speech, delays_speech, gains_speech);
tsn_filtered = tsn_filtered(1+round(5*fs):end-round(5*fs),:);
tsnlevel = 20.*log10(sqrt(mean(tsn_filtered(:,referencechannel).^2)));
% Calculate required gain using the test specific noise as reference
speechgain = (targetlevel-referencelevel) - tsnlevel;

% Process speech files
speechfiles = dir([sourcedir filesep 'speech' filesep '*.wav']);
files = {speechfiles.name};
for i=1:length(files)
  sourcefile = [sourcedir filesep 'speech' filesep files{i}];
  targetfile = [targetdir filesep  'speech' filesep 'default' filesep files{i}];
  signal = audioread_cell({sourcefile}, fs, 1);
  signal = signal{1};
  signal = [zeros(round(1.00.*fs),1); signal; zeros(round(1.00.*fs),1)];
  signal_filtered = mix(signal, hrir_speech, delays_speech, gains_speech);
  signal_filtered = signal_filtered(1+round(1.00.*fs):end-round(0.75.*fs),:);
  signal_filtered = signal_filtered .* 10.^(speechgain./20);
  audiowrite(targetfile, signal_filtered, fs, 'BitsPerSample', 32);
end

% Process maskers and add microphone noise to maskers!
maskerfiles = dir([sourcedir filesep 'maskers' filesep '*.wav']);
files = {maskerfiles.name};
for i=1:length(files)
  sourcefile = [sourcedir filesep 'maskers' filesep files{i}];
  targetfile = [targetdir filesep 'maskers' filesep files{i}];
  signal = audioread_cell({sourcefile}, fs, 1);
  signal = signal{1};
  signal = crossfade_extend( ...
    signal, round(fs.*0.25), round(fs.*(maskerlength+10)) ...
  );
  signal_filtered = mix(signal, hrir_masker, delays_masker, gains_masker);
  signal_filtered = signal_filtered(1+round(5*fs):end-round(5*fs),:);
  maskerlevel = 20.*log10(sqrt(mean(signal_filtered(:,referencechannel).^2)));
  if maskerlevel > -Inf
    maskergain = (targetlevel-referencelevel) - maskerlevel;
    signal_filtered = signal_filtered .* 10.^(maskergain./20);
  end
  noise_offset = floor(rand(1).*(size(pinknoise,1)-size(signal_filtered,1)-1));
  noise_tmp = pinknoise(1+noise_offset:size(signal_filtered,1)+noise_offset,:);
  % apply microphone noise
  signal_filtered(:,[2,3,4]) = signal_filtered(:,[2,3,4]) + noise_tmp(:,[2,3,4]);
  audiowrite(targetfile, signal_filtered, fs, 'BitsPerSample', 32);
end

