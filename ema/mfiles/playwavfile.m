function playwavfile(filename, ear, device)
  % Get audio data
  [signal, fs] = audioread(filename);
  if isempty(signal)
    error('Could not read wav file');
  end
  
  % Find device ID for audio playback
  playdev = audiodevinfo(0,sprintf('%s (JACK Audio Connection Kit)',device));
  if isempty(playdev)
    error(sprintf('Could not find playback device: %s\n',device));
  end

  % Mix up mono signals
  if size(signal,2) == 1
    signal = [signal, signal];
  end

  % Check for stereo signal
  if size(signal,2) ~= 2
    error('Number of channels not supported');
  end

  % Reduce playback to selected channel
  switch ear
    case 'l'
      signal(:,2) = 0;
    case 'r'
      signal(:,1) = 0;
    case 'b'
      
    otherwise
      error('Unknown ear definition (l/r/b)');
  end

  % Playback with 24bit samples on "playdev" (depends on capabilities of device, choose highest possible)
  signal = [signal; zeros(round(0.2.*fs),2)];
  player = audioplayer(signal, fs, 24, playdev);
  play(player);
  pause(size(signal,1)./fs);
  stop(player);
  pause(0.1);
end
