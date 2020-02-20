function [signal, fs] = gensweep(type, variable, condition)
  fs = 48000; % Hz
  reference_level = 130; % dB SPL
  sweep_duration = 0.200; % s
  sweep_width = [0.98 1.02];
  flank_duration = 0.020; % s
  sweep_samples = round(fs.*sweep_duration);
  flank_samples = round(fs.*flank_duration);

  % parse condition string
  condition = regexp(condition,',','split');
  [frequency, ear] = condition{:};
  frequency = str2num(frequency);

  % Generate stimulus
  if type > 0
    signal = sinesweepphase(sweep_samples, sweep_width.*frequency./fs, rand(1).*2.*pi);
    signal = normalize(signal, variable - reference_level);
    signal = flank(signal, flank_samples);
  else
    signal = zeros(sweep_samples,1);
  end

  % Mix up mono signals
  if size(signal,2) == 1
    signal = [signal, signal];
  end

  % Select playback channels
  switch ear
    case 'l'
      signal(:,2) = 0;
    case 'r'
      signal(:,1) = 0;
    case 'b'

    otherwise
      error('Unknown ear definition (l/r/b)');
  end
end
