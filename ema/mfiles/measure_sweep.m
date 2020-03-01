function measure_sweep(targetfile, parameters, device)

  % SIAM configuration
  target = 0.75;
  minreversals = 14;
  discardreversals = 4;
  minmeasures = 25;
  startvalue = 60; % dB SPL
  steps = [8 8 4 2];
  feedback = 0;

  % Create an adaptation parameter config string
  adaptconfig = sprintf('target=%.2f;minreversals=%i;discardreversals=%i;minmeasures=%i;startvalue=%.2f;steps=[%s];feedback=%i;', ...
    target, minreversals, discardreversals, minmeasures, startvalue, num2str(steps), feedback);

  % Configure presentstimulus
  presentstimulus([], [], parameters, device);

  % Make start value adaptable
  startvalue_corrected = startvalue;

  % Demo Stimulus
  answer = 0;
  while answer == 0
    validanswer = 0;
    presentstimulus(1, startvalue_corrected);
    while validanswer == 0
      answer = input(sprintf('%3i|  1) present  0) absent  a) abort  -->  ',0),'s');
      switch tolower(answer)
        case {'0', '1'}
          validanswer = 1;
        case {'a'}
          validanswer = 2;
      end
    end
    % Evaluate answer
    switch validanswer
      case 1
        answer = str2num(answer);
      case 2
        exit
    end
    if answer == 0
      startvalue_corrected = startvalue_corrected + steps(1);
    end
  end

  % Start single interval adaptive measurement
  [threshold, values, reversals, measures, presentations, answers, adjustments] = ...
    siam(@presentstimulus, @getanswer, target, minreversals, discardreversals, minmeasures, startvalue_corrected, steps, feedback);

  % Rename target file for incomplete measurements
  if isempty(threshold)
    targetfile = [targetfile, '.incomplete'];
    printf('\n# CONDITION %s FAILED\n', targetfile);
  else
    printf('\n# CONDITION %s THRESHOLD %.2f\n', targetfile, threshold);
  end

  % Save results
  fid = fopen(targetfile,'w');
  if fid>0
    fprintf(fid,'%s\n', adaptconfig);
    fprintf(fid,'threshold = [');
    fprintf(fid,'%.2f ', threshold);
    fprintf(fid,'];\n');
    fprintf(fid,'values = [');
    fprintf(fid,'%.2f ', values);
    fprintf(fid,'];\n');
    fprintf(fid,'reversals = [');
    fprintf(fid,'%i ', reversals);
    fprintf(fid,'];\n');
    fprintf(fid,'measures = [');
    fprintf(fid,'%i ', measures);
    fprintf(fid,'];\n');
    fprintf(fid,'presentations = [');
    fprintf(fid,'%i ', presentations);
    fprintf(fid,'];\n');
    fprintf(fid,'answers = [');
    fprintf(fid,'%i ', answers);
    fprintf(fid,'];\n');
    fprintf(fid,'adjustments = [');
    fprintf(fid,'%i ', adjustments);
    fprintf(fid,'];\n');
    fprintf(fid,'\n');
    fclose(fid);
  else
    error('Could not open target file');
  end

  % Plot run
  showfigure = 'empty';
  while ~any(strcmp(showfigure,{'y','n',''}))
    showfigure = tolower(input('Do you want to plot this run? (y/N): ','s'));
  end
  if strcmp(showfigure,'y')
    plot_run(targetfile, 0);
  end
end

function offset = presentstimulus(presentation, value, parameters, device)
  offset = nan;

  % Use persistent variables for configuration
  persistent cache;
  if nargin > 2
    cache.count = 0;
    cache.id = rand(1);
    cache.parameters = parameters;
    cache.device = device;
    cache.stimulusplayer = [];
  else
    parameters = cache.parameters;
    device = cache.device;
    if ~isempty(cache.stimulusplayer)
      stop(cache.stimulusplayer);
    end
  end

  cache.count = cache.count + 1;
  if isempty(presentation)
    return
  end

  % Generate the sweep using the sweep stimulus function
  [stimulus, fs] = gensweep(presentation, value, parameters);

  % The Octave audioplayer cannot reproduce more than 2 channels
  %cache.stimulusplayer = audioplayer(stimulus, fs, 24, playdev);
  %play(cache.stimulusplayer);
  filename = sprintf('/dev/shm/audioplayer-tmp-%010.0f-%i.wav', cache.id.*1E10, cache.count);
  audiowrite(filename, stimulus, fs, 'BitsPerSample', 32);
  status = unix(['./playsound.sh "', filename, '" "', device, '" 1 1>/dev/null 2>/dev/null &']);
end

function answer = getanswer(count)
  validanswer = 0;
  while validanswer == 0
    answer = input(sprintf('%3i|  1) present  0) absent  a) abort  -->  ',count),'s');
    switch tolower(answer)
      case {'0', '1'}
        validanswer = 1;
      case {'a'}
        validanswer = 2;
    end
  end
  
  % Evaluate answer
  switch validanswer
    case 1
      answer = str2num(answer);
    case 2
      exit
  end
end
