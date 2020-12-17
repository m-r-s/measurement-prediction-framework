function measure_loudness(targetfile, parameters, device)
  % Work with 48kHz sample rate
  fs = 48000;

  % Find device ID for audio playback
  playdev = audiodevinfo(0,sprintf('%s (JACK Audio Connection Kit)',device));
  if isempty(playdev)
    error(sprintf('Could not find playback device: %s\n',device));
  end

  % Get parameter variables from string
  parameters_parts = strsplit(parameters, ',');
  [sampleset, ear] = parameters_parts{:};
  sampledir = ['loudness', filesep, sampleset];

  if ~exist(sampledir, 'dir')
    printf('Error: sampledir not found!\n');
    error('sampledir not found');
  end
  
  samplefiles = dir([sampledir filesep '*.wav']);
  samplefiles = sort({samplefiles.name});
  
  if isempty(samplefiles)
    printf('Error: no samples found in sampledir!\n');
    error('no samples found');
  end
  
  % Load samples
  samples = cell(size(samplefiles));
  for i=1:numel(samples)
    samplefile = [sampledir filesep samplefiles{i}];
    if ~exist(samplefile,'file')
      printf('Error: samplefile not found!\n');
      error('samplefile not found');
    end
    [signal, samplefs] = audioread(samplefile);
    % Resample if required
    if samplefs ~= fs
      signal = resample(signal, fs, samplefs);
    end
    % Mix up mono signals
    if size(signal,2) == 1
      signal = [signal, signal];
    end
    % Check for stereo signal
    if size(signal,2) ~= 2
      error('Number of channels not supported');
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
    samples{i} = signal;
  end

  % Configure presentstimulus
  presentstimulus([], samples, fs, playdev);
 
  % Random sample order for measurement
  [~, sampleorder] = sort(rand(numel(samples),1));
  samplefiles(sampleorder)
  % Start loudness measurement
  [presentations, answers] = presentationresponse(@presentstimulus, @getanswer, sampleorder);

  % Rename target file for incomplete measurements
  if numel(answers) < numel(samples)
    targetfile = [targetfile, '.incomplete'];
    printf('\n# CONDITION %s FAILED\n', targetfile);
  else
    printf('\n# CONDITION %s ANSWERS %i MEDIAN %.1f\n', targetfile, numel(answers), median(answers));
  end

  % Save results
  fid = fopen(targetfile,'w');
  if fid>0
    fprintf(fid,'threshold = [%.1f];\n',median(answers));
    fprintf(fid,'samplefiles = {');
    for i=1:numel(samplefiles)
      fprintf(fid,'''%s'' ', samplefiles{i});
    end
    fprintf(fid,'};\n');
    fprintf(fid,'presentations = [');
    fprintf(fid,'%i ', presentations);
    fprintf(fid,'];\n');
    fprintf(fid,'answers = [');
    fprintf(fid,'%i ', answers);
    fprintf(fid,'];\n');
    fprintf(fid,'\n');
    fclose(fid);
  else
    error('Could not open target file');
  end
end

function presentstimulus(presentation, samples, fs, playdev)
  padd_duration = 0.500; % s
  flank_duration = 0.100; % s

  % Use persistent variables for configuration
  persistent cache;
  if nargin > 1
    cache.count = 0;
    cache.id = rand(1);
    cache.samples = samples;
    cache.fs = fs;
    cache.playdev = playdev;
    cache.stimulusplayer = [];
  else
    samples = cache.samples;
    fs = cache.fs;
    playdev = cache.playdev;
    if ~isempty(cache.stimulusplayer)
      stop(cache.stimulusplayer);
    end
  end

  flank_samples = round(fs.*flank_duration);
  padd_samples = round(fs.*padd_duration);

  cache.count = cache.count + 1;
  if isempty(presentation)
    return
  end

  % Generate stimulus
  sample_tmp = samples{presentation};
  %20*log10(rms(sample_tmp))+130  % rms level in dB
  sample_tmp = [zeros(padd_samples,size(sample_tmp,2)); sample_tmp; zeros(padd_samples,size(sample_tmp,2))];
  stimulus = flank(sample_tmp, flank_samples);
  
  % Playback with 24bit samples on "playdev" (depends on capabilities of device, choose highest possible)
  stimulus = [stimulus; zeros(round(0.1.*fs),2)];
  cache.stimulusplayer = audioplayer(stimulus, fs, 24, playdev);
  play(cache.stimulusplayer);
end

function answer = getanswer(count)
  % Get a valid answer
  validanswer = 0;
  while validanswer == 0
    answer = input(sprintf('%3i|  perceived loudness?  0 (inaudible) - 10 (too loud), a - abort  -->  ',count),'s');
    switch tolower(answer)
      case {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'}
        validanswer = 1;
      case {'a'}
        validanswer = 2;
      otherwise
        printf('%3i|  INCORRECT ANSWER!\n',count);
    end
  end
  
  % Evaluate and store answer
  switch validanswer
    case 1
      answer = str2num(answer);
    case 2
      exit
  end
end
