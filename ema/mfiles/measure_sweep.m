function measure_sweep(targetfile, parameters, device)
  % Find device ID for audio playback
  playdev = audiodevinfo(0,sprintf('%s (JACK Audio Connection Kit)',device));
  if isempty(playdev)
    error(sprintf('Could not find playback device: %s\n',device));
  end

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
  presentstimulus([], [], parameters, playdev);

  % Make start value adaptable
  startvalue_corrected = startvalue;

  % Demo Stimulus
  answer = 0;
  while answer == 0
    validanswer = 0;
    status = presentstimulus(1, startvalue_corrected);
    if status > 0
      break
    end   
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
  
  if status > 0 
    threshold = inf;
    values = [];
    reversalsv = [];
    measures = [];
    presentations = [];
    answers = [];
    adjustments = [];
  else
    % Start single interval adaptive measurement
    [threshold, values, reversals, measures, presentations, answers, adjustments] = ...
      siam(@presentstimulus, @getanswer, target, minreversals, discardreversals, minmeasures, startvalue_corrected, steps, feedback);
  end
  
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

function [status, offset] = presentstimulus(presentation, value, parameters, playdev)
  offset = nan;

  % Use persistent variables for configuration
  persistent cache;
  if nargin > 2
    cache.count = 0;
    cache.warnings = 0;
    cache.id = rand(1);
    cache.parameters = parameters;
    cache.playdev = playdev;
    cache.stimulusplayer = [];
  else
    parameters = cache.parameters;
    playdev = cache.playdev;
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

  if ~checklevels(stimulus)
    cache.warnings = cache.warnings + 1;
    printf('Warning! Level check on last stimulus failed (%i/3)!\n', cache.warnings);
  end
  
  if cache.warnings < 3
    % Playback with 24bit samples on "playdev" (depends on capabilities of device, choose highest possible)
    stimulus = [stimulus; zeros(round(0.1.*fs),2)];
    cache.stimulusplayer = audioplayer(stimulus, fs, 24, playdev);
    play(cache.stimulusplayer);
    status = 0;
  else
    printf('Warning threshold exceeded. Abort measurement!\n');
    status = 1;
  end
  
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

