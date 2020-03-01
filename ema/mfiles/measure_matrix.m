function measure_matrix(targetfile, parameters, device)
  % Work with 48kHz sample rate
  fs = 44100;

  % Adaptive configuration
  target = 0.5;
  discardreversals = 2;
  startvalue = 0;
  steps = [4 2 1];
  selfservice = 1;

  % Create an adaptation parameter config string
  adaptconfig = sprintf('target=%.2f;discardreversals=%i;startvalue=%.2f;steps=[%s];selfservice=%i;', ...
    target, discardreversals, startvalue, num2str(steps), selfservice);

  % Load lists and shuffle
  matrix_lists;
  [~, shuffle] = sort(rand(numel(lists),1));
  lists = lists(shuffle);

  % Get parameter variables from string
  parameters_parts = strsplit(parameters, ',');
  [talker, masker, level] = parameters_parts{:};
  level = str2double(level);
  
  % Interpret start value
  switch masker
    case 'quiet'
      startvalue = 65-level;
    case 'icra1'
      startvalue = 0;
    case 'icra5.250'
      startvalue = 0;
  end

  noisefile = ['matrix' filesep 'maskers', filesep, masker, '.wav'];

  if ~exist(noisefile, 'file')
    printf('Error: noisefile not found!\n');
    error('noisefile not found');
  end

  [signal, noisefs] = audioread(noisefile);
  % Adjust level
  signal = signal .* 10.^((level-65)./20);
  % Resample if required
  if noisefs ~= fs
    signal = resample(signal, fs, noisefs);
  end
  noise = signal;
  
  % Shuffle a random list and use it
  listidx = ceil(eps+rand(1).*numel(lists));
  list_tmp = lists{listidx};
  [~, shuffle] = sort(rand(numel(list_tmp),1));
  list_tmp = list_tmp(shuffle);
  
  % Load speech recordings
  speech = cell(size(list_tmp));
  for i=1:numel(list_tmp)
    speechfile = ['matrix' filesep 'speech' filesep talker filesep list_tmp{i} '.wav'];
    if ~exist(speechfile,'file')
      printf('Error: speechfile not found!\n');
      error('speechfile not found');
    end
    [signal, speechfs] = audioread(speechfile);
    % Adjust level
    signal = signal .* 10.^((level-65)./20);
    % Resample if required
    if speechfs ~= fs
      signal = resample(signal, fs, speechfs);
    end
    speech{i} = signal;
  end

  % Configure presentstimulus
  presentstimulus([], [], speech, noise, fs, device);

  % Start adaptive matrix measurement
  [threshold, values, reversals, measures, presentations, answers, adjustments, offsets] =...
    matrixadapt(@presentstimulus, @getanswer, target, discardreversals, startvalue, steps, list_tmp, selfservice);

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
    fprintf(fid,'sentences = {');
    for j=1:numel(list_tmp)
      fprintf(fid,'''%s'' ', list_tmp{j});
    end
    fprintf(fid,'};\n');
    fprintf(fid,'offsets = [');
    fprintf(fid,'%i ', offsets);
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

function noise_offset = presentstimulus(presentation, value, speech, noise, fs, device)
  padd_duration = 0.500; % s
  flank_duration = 0.100; % s

  % Use persistent variables for configuration
  persistent cache;
  if nargin > 2
    cache.count = 0;
    cache.id = rand(1);
    cache.speech = speech;
    cache.noise = noise;
    cache.fs = fs;
    cache.device = device;
    cache.stimulusplayer = [];
  else
    speech = cache.speech;
    noise = cache.noise;
    fs = cache.fs;
    device = cache.device;
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
  speech_tmp = speech{presentation};
  speech_tmp = [zeros(padd_samples,size(speech_tmp,2)); speech_tmp; zeros(padd_samples,size(speech_tmp,2))];
  noise_offset = floor(rand(1).*(size(noise,1)-size(speech_tmp,1)-1));
  noise_tmp = noise(1+noise_offset:size(speech_tmp,1)+noise_offset,:);
  speechinnoise = speech_tmp .* 10.^(value./20) + noise_tmp;
  stimulus = flank(speechinnoise, flank_samples);
  
  % The Octave audioplayer cannot reproduce more than 2 channels
  %cache.stimulusplayer = audioplayer(stimulus, fs, 24, playdev);
  %play(cache.stimulusplayer);
  filename = sprintf('/dev/shm/audioplayer-tmp-%010.0f-%i.wav', cache.id.*1E10, cache.count);
  audiowrite(filename, stimulus, fs, 'BitsPerSample', 32);
  status = unix(['./playsound.sh "', filename, '" "', device, '" 1 1>/dev/null 2>/dev/null &']);
end

function answer = getanswer(count, explanationidx)
  persistent cache;
  if isempty(cache)
    % Load explanations
    matrix_explanation;
    cache.explanation = explanation;
  else
    explanation = cache.explanation;
  end
  
  % Prepare explanation
  explanationidx1 = str2num(explanationidx(1));
  explanationidx2 = str2num(explanationidx(2));
  explanationidx3 = str2num(explanationidx(3));
  explanationidx4 = str2num(explanationidx(4));
  explanationidx5 = str2num(explanationidx(5));
  explanation_tmp = [ ...
    explanation{1+explanationidx1,1} ' ' ...
    explanation{1+explanationidx2,2} ' ' ...
    explanation{1+explanationidx3,3} ' ' ...
    explanation{1+explanationidx4,4} ' ' ...
    explanation{1+explanationidx5,5} ...
    ];
  
  % Get a valid answer
  validanswer = 0;
  while validanswer == 0
    answer = input(sprintf('%3i|  "%s"  (#correct, a - abort)  -->  ',count,explanation_tmp),'s');
    switch tolower(answer)
      case {'0', '1', '2', '3', '4', '5'}
        validanswer = 1;
      case {'a'}
        validanswer = 2;
    end
  end
  
  % Evaluate and store answer
  switch validanswer
    case 1
      answer = str2num(answer);
    case 2
      exit
  end
  answers(count) = answer;
end
