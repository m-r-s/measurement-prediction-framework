function [features, signal, log_melspec] = feature_extraction(signal, fs, individualization, id, ear)
%
% Feature extraction for simulating HZ study experiments
%

if nargin < 3 || isempty(individualization)
  individualization = '';
end

if nargin < 4 || isempty(id)
  id = 'P-0-0';
end

% config cache
persistent config;

% Config id string
configid = sprintf('fs%.0fIND%sID%s', fs, individualization, id);

% Hearing status can be cached
if isempty(config) || ~isfield(config, configid)
  % Load hearing thresholds (ht) and level uncertainty (ul)
  [f, ht, ul] = load_hearingstatus(id, individualization);
  config.(configid).ht = ht;
  config.(configid).ul = ul;
  config.(configid).f = f;
else
  ht = config.(configid).ht;
  ul = config.(configid).ul;
  f = config.(configid).f;
end

% Select the target ear
switch ear
  case 'l'
    signal = signal(:,1);
  case 'r'
    signal = signal(:,2);
end

% Skip the first 100ms of the output
% Randomize the start sample by another 10ms
signal = signal(1+round(fs.*(0.100+rand(1).*0.010)):end);

% Calculate log Mel-spectrogram
[log_melspec, melspec_freqs] = log_mel_spectrogram(signal, fs);

% Apply absolute hearing threshold
ht_mel = interp1(f(:), ht(:), melspec_freqs(:), 'linear', 'extrap');
log_melspec = max(bsxfun(@minus, log_melspec, ht_mel), randn(size(log_melspec)));

% Apply frequency-dependent level-uncertainty
ul_mel = interp1(f(:), ul(:), melspec_freqs(:), 'linear', 'extrap');
ul_mel(isnan(ul_mel)) = 0.1;
log_melspec = bsxfun(@times,log_melspec,1./ul_mel) + randn(size(log_melspec));

% SGBFB feature extraction and mean-and-variance normalization
features = mvn(sgbfb(log_melspec));
end

