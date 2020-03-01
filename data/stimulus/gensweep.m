function [signal, fs] = gensweep(type, variable, condition)
  fs = 44100; % Hz
  reference_level = 130; % dB SPL
  sweep_duration = 0.500; % s
  sweep_width = [1 1];
  flank_duration = 0.010; % s
  sweep_samples = round(fs.*sweep_duration);
  flank_samples = round(fs.*flank_duration);

  % parse condition string
  condition = regexp(condition,',','split');
  frequency = condition{:};
  frequency = str2num(frequency);

  % Generate stimulus
  if type > 0
    signal = sinesweepphase(sweep_samples, sweep_width.*frequency./fs, rand(1).*2.*pi);
    signal = normalize(signal, variable - reference_level);
    signal = flank(signal, flank_samples);
  else
    signal = zeros(sweep_samples,1);
  end

  % Play back on first channel of 4
  signal = [signal, zeros(size(signal,1),3)];
end
