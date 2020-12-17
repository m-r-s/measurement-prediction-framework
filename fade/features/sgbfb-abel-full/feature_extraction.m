function features = feature_extraction(signal, fs, id)
% usage: features = feature_extraction(signal, fs, id)
%   signal        waveform signal
%   fs            sample rate in Hz
%   id            listener string that is then handled by load_hearingprofile.m
%
% - Feature extraction to take binaural hearing thresholds into account -
%
%
% Copyright (C) 2019-2020 Marc René Schädler
% E-mail marc.r.schaedler@uni-oldenburg.de
% Institute Carl-von-Ossietzky University Oldenburg, Germany
%
%-----------------------------------------------------------------------------
%
% Release Notes:
% v1.0 - Inital release
%

if nargin < 3 || isempty(id)
  id = 0;
end

if nargin < 4 || isempty(uncertainty)
  uncertainty = 1;
end

persistent config;

% Config id string
configid = sprintf('c%.0f', fs, id);

if isempty(config) || ~isfield(config, configid)
  % Load hearing profile
  [hp_frequencies, hp_thresholds, hp_uncertainties] = load_hearingprofile(id);
  config.(configid).hp_frequencies = hp_frequencies;
  config.(configid).hp_thresholds = hp_thresholds;
  config.(configid).hp_uncertainties = hp_uncertainties;
else
  hp_frequencies = config.(configid).hp_frequencies;
  hp_thresholds = config.(configid).hp_thresholds;
  hp_uncertainties = config.(configid).hp_uncertainties;
end

% Skip the first 100ms of the output
% Randomize the start sample by another 10ms
signal = single(signal(1+round(fs.*(0.100+rand(1).*0.010)):end,:));

if size(signal,2) == 1
  signal = [signal, signal];
end

% SGBFB ABEL feature extraction
% Separate left and right channel
signal_left = signal(:,1);
signal_right = signal(:,2);

% Calculate log Mel-spectrograms
[log_melspec_left, melspec_freqs_left] = log_mel_spectrogram(signal_left, fs);
[log_melspec_right, melspec_freqs_right] = log_mel_spectrogram(signal_right, fs);

% Get left and right hearing thresholds
ht_left = interp1(hp_frequencies, hp_thresholds(1,:), melspec_freqs_left, 'linear', 'extrap');
ht_right = interp1(hp_frequencies, hp_thresholds(2,:), melspec_freqs_right, 'linear', 'extrap');

% Apply absolute hearing threshold
log_melspec_left = max(log_melspec_left - ht_left.', 0);
log_melspec_right = max(log_melspec_right - ht_right.', 0);

% Apply frequency-dependent level-uncertainty
ul_mel_left = interp1(hp_frequencies, hp_uncertainties(1,:), melspec_freqs_left, 'linear', 'extrap');
ul_mel_right = interp1(hp_frequencies, hp_uncertainties(2,:), melspec_freqs_right, 'linear', 'extrap');
ul_mel_left(isnan(ul_mel_left)) = 0.1;
ul_mel_right(isnan(ul_mel_right)) = 0.1;
log_melspec_left = log_melspec_left ./ ul_mel_left.' + randn(size(log_melspec_left));
log_melspec_right = log_melspec_right ./ ul_mel_right.' + randn(size(log_melspec_right));

% Extract SGBFB features (with adapted parameters to compensate the spectral super-sampling)
features_left = sgbfb(single(log_melspec_left));
features_right = sgbfb(single(log_melspec_right));

% Concatenate feature vectors and perform mean and variance normalization
features = mvn([features_left; features_right]);
end

