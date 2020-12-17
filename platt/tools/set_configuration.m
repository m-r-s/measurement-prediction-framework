%% CONSTANTS (32 bit all the way)
% These values must be the same as in (constants.h)
SAMPLERATE = single(48000); % Sample rate in Hz
NUMFILTERS = int32(78); % Number of Gammatone filters
GTLEVELS = int32(131); % gain table levels
GTMIN = int32(0); % minimum level in gain table
ORDER = int32(4); % Order of Gammatone filters
TICKSAMPLES = int32(48); % Samples per tick (update)
TICKSIZE = int32(52); % Samples per tick plus samples for initial state (=ORDER)
MAXHOLDTICKS = int32(15); % Number of ticks to hold maxima (~15ms)
MAXDECAY = single(1.0); % Max decay of maxima in dB/tick
LOG2DB = single(8.6858896380650350); % Pre-calculated value for dB calculation
NUMLAYERS = int32(6); % Number of dynamic layers
COMPRESSIONMARGIN = single(0.5);
GAINCORRECTION = single(-9.5602); % dB

% Sample rate
fs = double(SAMPLERATE);


%% GAMMATONE FILTER BANK COEFFICIENTS
% Considered frequency range in Hz
freq_range = [64 16000];
% Integer super-sampling factor
spectral_supersample = 2; % 1 means ~ 1 ERB
% Gammatone filter quality Duration/delay vs. spectral resolution trading
qcontrol = 2;

% Separatly save real and imaginary parts of b0 and a1
% Impulse to measure impulse response
signal = [zeros(100,1); 1; zeros(fs-101,1)];
[signal_filtered, centers, filters] = mel_gammatone_iir(signal, fs, freq_range, spectral_supersample, qcontrol);
assert(length(filters) == NUMFILTERS, 'NUMFILTERS does not match number of filters');
% Center frequencies of Mel bands
freqs = single(centers);
% Recursive Gammatone filter coefficients (a1) and phase and amplitude (b0)
b0 = filters(:,1);
a1 = filters(:,2);

% Arrange data for efficient access
coeff = zeros(NUMFILTERS.*4,1,'single');
coeff(1:4:end) = real(b0);
coeff(2:4:end) = imag(b0);
coeff(3:4:end) = real(a1);
coeff(4:4:end) = imag(a1);

%% CALIBRATION
% Interpolate calibration at Mel band center frequencies
calib_in = interp1(cfg_freqs,cfg_calib_in,centers);
calib_out = interp1(cfg_freqs,cfg_calib_out,centers);
calibration = zeros(NUMFILTERS*2,1,'single');
calibration(1:2:end) = calib_in;
calibration(2:2:end) = calib_out;


%% SPECTRAL MASKING
% Use impulse responses to estimate spectral overlap (masking) of filters
filters_fft = double(abs(fft(real(signal_filtered))));
filter_gain = -inf(length(filters),length(filters).*2-1);
for i=1:length(filters)
  filter_fft_interp = interp1(0:fs-1,20*log10(filters_fft(:,i)),centers);
  filter_gain(i,(1:length(filters))-i+length(filters)) = filter_fft_interp;
end
% Assume that the masking pattern is invariant on the Mel frequency scale
% and take the maximum.
% This provides one global spectral masking function.
spectralmask = max(filter_gain);
spectralmask(length(filters)) = 0; % This really should be zero
% Apply the spectral boost factor which assumes increased spectral masking
spectralmask = single(real(spectralmask).*(1-spectral_boost));

% Use this code to plot the spectral masking function
%figure;
%plot(filter_gain.');
%hold on
%plot(spectralmask(1:2*NUMFILTERS-1),'k');
%plot(spectralmask(2*NUMFILTERS:end),'k--');


%% INPUT/OUTPUT
% This is a sensible part of the configuration
% The following steps are calculating the input output functions:

% 1. Apply threshold offset
cfg_threshold1 = cfg_threshold1 + threshold_offset;
cfg_threshold2 = cfg_threshold2 + threshold_offset;
cfg_normal_threshold = cfg_normal_threshold + threshold_offset;

% 2. Ignore thresholds below normal hearing
cfg_threshold1 = max(cfg_threshold1, cfg_normal_threshold);
cfg_threshold2 = max(cfg_threshold2, cfg_normal_threshold);

% 3. Start with hearing threshold for lower input level
cfg_level_in_low1 = cfg_threshold1 + guard_intervals(1);
cfg_level_in_low2 = cfg_threshold2 + guard_intervals(1);

% 4. Make sounds that need attention audible
cfg_level_in_low1 = min(cfg_level_in_low1, cfg_attention_threshold);
cfg_level_in_low2 = min(cfg_level_in_low2, cfg_attention_threshold);

% 5. Start with hearing threshold for lower output level
cfg_level_out_low1 = cfg_threshold1 + guard_intervals(1);
cfg_level_out_low2 = cfg_threshold2 + guard_intervals(1);

% 6. We don't want attenuation on the lower end
cfg_level_out_low1 = max(cfg_level_out_low1, cfg_level_in_low1);
cfg_level_out_low2 = max(cfg_level_out_low2, cfg_level_in_low2);

% 7. We don't want to make soft sound uncomfortably loud
cfg_level_out_low1 = min(cfg_level_out_low1, cfg_uncomfortable1-20);
cfg_level_out_low2 = min(cfg_level_out_low2, cfg_uncomfortable2-20);

% 8. Start below uncomfortable level (with compression we get close to it)
cfg_level_out_high1 = cfg_uncomfortable1 - guard_intervals(2);
cfg_level_out_high2 = cfg_uncomfortable2 - guard_intervals(2);

% 9. Map below "normal" uncomfortable level
cfg_level_in_high1 = cfg_normal_uncomfortable - guard_intervals(2);
cfg_level_in_high2 = cfg_normal_uncomfortable - guard_intervals(2);

% Input/Output dynamic
% Interpolate the results at Mel band center frequencies
level_in_high1 = interp1(cfg_freqs, cfg_level_in_high1, centers, 'linear', 'extrap');
level_in_low1 = interp1(cfg_freqs, cfg_level_in_low1, centers, 'linear', 'extrap');
level_out_high1 = interp1(cfg_freqs, cfg_level_out_high1, centers, 'linear', 'extrap');
level_out_low1 = interp1(cfg_freqs, cfg_level_out_low1, centers, 'linear', 'extrap');  
level_in_high2 = interp1(cfg_freqs, cfg_level_in_high2, centers, 'linear', 'extrap');
level_in_low2 = interp1(cfg_freqs, cfg_level_in_low2, centers, 'linear', 'extrap');
level_out_high2 = interp1(cfg_freqs, cfg_level_out_high2, centers, 'linear', 'extrap');
level_out_low2 = interp1(cfg_freqs, cfg_level_out_low2, centers, 'linear', 'extrap');  

% Use this code to plot the defined working points
%figure;
%subplot(2,1,1);
%plot(level_in_high1,'b');
%hold all
%plot(level_in_low1,'b');
%plot(level_out_high1,'r');
%plot(level_out_low1,'r');
%subplot(2,1,2);
%plot(level_in_high2,'b');
%hold all
%plot(level_in_low2,'b');
%plot(level_out_high2,'r');
%plot(level_out_low2,'r');

% Arrange data for efficient access
io_left = zeros(NUMFILTERS*4,1,'single');
io_left(1:4:end) = level_in_low1;
io_left(2:4:end) = level_in_high1;
io_left(3:4:end) = level_out_low1;
io_left(4:4:end) = level_out_high1;

io_right = zeros(NUMFILTERS*4,1,'single');
io_right(1:4:end) = level_in_low2;
io_right(2:4:end) = level_in_high2;
io_right(3:4:end) = level_out_low2;
io_right(4:4:end) = level_out_high2;


%% GAINTABLE
if isempty(gt_data)
  gt_left = zeros(NUMFILTERS,GTLEVELS,'single');
  for i=1:NUMFILTERS
    in_tmp = [level_in_low1(i);level_in_high1(i)];
    gain_tmp = [level_out_low1(i)-level_in_low1(i);level_out_high1(i)-level_in_high1(i)];
    gt_left(i,:) = interp1([-100;in_tmp;200],gain_tmp([1,1:end,end]),0:1:130,'linear','extrap');
  end
  gt_right = zeros(NUMFILTERS,GTLEVELS,'single');
  for i=1:NUMFILTERS
    in_tmp = [level_in_low2(i);level_in_high2(i)];
    gain_tmp = [level_out_low2(i)-level_in_low2(i);level_out_high2(i)-level_in_high2(i)];
    gt_right(i,:) = interp1([-100;in_tmp;200],gain_tmp([1,1:end,end]),0:1:130,'linear','extrap');
  end
else
  % Interpolate custom gain table
  gt_left = interp1(gt_freqs(:),gt_data(1:end/2,:),centers(:),'linear','extrap');
  gt_right = interp1(gt_freqs(:),gt_data(end/2+1:end,:),centers(:),'linear','extrap');
end
% Convert to single precision and sort levels first
gt_left = single(gt_left.'(:));
gt_right = single(gt_right.'(:));


%% EXPANSION
% These values are used as factors to expand some speech-relevant parts of the dynamic 
expansion_left = single(interp1(cfg_freqs, cfg_expansion1, centers, 'linear', 'extrap'));
expansion_right = single(interp1(cfg_freqs, cfg_expansion2, centers, 'linear', 'extrap'));


%% THRESHOLDS
% Interpolate relevant threshold at Mel band center frequencies
thresh_nh = interp1(cfg_freqs, cfg_normal_threshold, centers, 'linear', 'extrap');
uncomf_nh = interp1(cfg_freqs, cfg_normal_uncomfortable, centers, 'linear', 'extrap');
thresh1 = interp1(cfg_freqs, cfg_threshold1, centers, 'linear', 'extrap');
thresh2 = interp1(cfg_freqs, cfg_threshold2, centers, 'linear', 'extrap');
uncomf1 = interp1(cfg_freqs, cfg_uncomfortable1, centers, 'linear', 'extrap');
uncomf2 = interp1(cfg_freqs, cfg_uncomfortable2, centers, 'linear', 'extrap');
transm1 = interp1(cfg_freqs, cfg_transmission1, centers, 'linear', 'extrap');
transm2 = interp1(cfg_freqs, cfg_transmission2, centers, 'linear', 'extrap');
speaker_maxlevel = interp1(cfg_freqs, cfg_speaker_maxlevel, centers, 'linear', 'extrap');
% The uncomfortable level is taken into account in the maximum level
maxlevel1 = min(uncomf1,speaker_maxlevel);
maxlevel2 = min(uncomf2,speaker_maxlevel);

% Limit frequency range (to positive dynamic range)
positive_dynamic1 = thresh1 < min(level_out_high1,maxlevel1);
positive_dynamic2 = thresh2 < min(level_out_high2,maxlevel2);
active_freqs = centers>=freq_range(1) & centers<=freq_range(2);
% Mute inactive frequencies and frequencies with "negative" dynamic,
% i.e., where the threshold is too high to be considered
mute1 = ~positive_dynamic1 | ~active_freqs;
mute2 = ~positive_dynamic2 | ~active_freqs;

% Everything is stored as 32bit float (aka "single")
thresholds_normal = single(thresh_nh);
uncomfortable_normal = single(uncomf_nh);
maxlevel_left = single(maxlevel1);
maxlevel_right = single(maxlevel2);
mute_left = single(mute1);
mute_right = single(mute2);
transmission_left = single(transm1);
transmission_right = single(transm2);

%% GAINRATE
% Calculate the maximum allowed gain change in 1 ms depending on the frequency 
gainrate = single(max_gainrate .* centers ./ 1000);
