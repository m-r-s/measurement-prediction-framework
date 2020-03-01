function [signal, fs] = gensweepinnoise(type, variable, condition)
  fs = 44100; % Hz
  reference_level = 130; % dB SPL
  stimulus_duration = 0.750; % s
  noise_width = [0.5 2.0];
  noise_level_spectral = 40;
  noise_flank_duration = 0.100; % s
  sweep_duration = 0.250; % s
  sweep_width = [1 1];
  sweep_flank_duration = 0.010; % s
  
  stimulus_samples = round(fs.*stimulus_duration);
  sweep_samples = round(fs.*sweep_duration);
  noise_flank_samples = round(fs.*noise_flank_duration);
  sweep_flank_samples = round(fs.*sweep_flank_duration);
  sweep_offset = round(fs.*(stimulus_duration-sweep_duration)./2);

  % parse condition string
  condition = regexp(condition,',','split');
  frequency = condition{:};
  frequency = str2num(frequency);
  noise_frequency = frequency;
  sweep_frequency = frequency;

  % Generate stimulus
  noise = bandpassnoise(stimulus_samples, noise_width.*noise_frequency./fs);
  noise = normalize(noise, noise_level_spectral - reference_level) .* sqrt(diff(noise_width.*noise_frequency));
  noise = flank(noise, noise_flank_samples);
  signal = noise;
  if type > 0
    sweep = sinesweepphase(sweep_samples, sweep_width.*sweep_frequency./fs, rand(1).*2.*pi);
    sweep = normalize(sweep, 65 + variable - reference_level);
    sweep = flank(sweep, sweep_flank_samples);
    signal(1+sweep_offset:sweep_samples+sweep_offset) = ...
      signal(1+sweep_offset:sweep_samples+sweep_offset) + sweep;
  end

  % Play back on first channel of 4
  signal = [signal, zeros(size(signal,1),3)];
end
