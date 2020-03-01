function [f, ht, ul] = load_hearingstatus(id, individualization);

% Detect requested profiles P-<HL profile>-<UL profile>
if strncmp(id,'P',1)
  % Split string
  profile = strsplit(id,'-');
  hl_profile = profile{2};
  ul_profile = profile{3};
  % Frequencies
  f =  [125  250  375  500  750  1000  1500  2000  3000  4000  6000  8000]; % Hz

  % Bisgaard profile hearing loss
  hl_profiles = [...
    10    10    10    10    10    10    10    15    20    30    40    40; ... % N1
    20    20    20    20    22.5  25    30    35    40    45    50    50; ... % N2
    35    35    35    35    35    40    45    50    55    60    65    65; ... % N3
    55    55    55    55    55    55    60    65    70    75    80    80; ... % N4
    65    65    67.5  70    72.5  75    80    80    80    80    80    80; ... % N5
    75    75    77.5  80    82.5  85    90    90    95   100   100   100; ... % N6
    90    90    92.5  95   100   105   105   105   105   105   105   105; ... % N7
    10    10    10    10    10    10    10    15    30    55    70    70; ... % S1
    20    20    20    20    22.5  25    35    55    75    95    95    95; ... % S2
    30    30    30    35    47.5  60    70    75    80    80    85    85; ... % S3
    30    30    30    30    30    30    30    30    30    30    30    30; ... % Special
  ];
  hl_profile = str2num(hl_profile);
  ul_profile = str2num(ul_profile);
  if hl_profile == 0
    hl = zeros(size(f));
  else
    hl = hl_profiles(hl_profile,:);
  end
  if ul_profile > 0
    ul = ul_profile .* ones(size(f));
  else
    ul = nan(size(f));
  end
  ht = ff2ed(f,hl2spl(f,hl)); % Level at eardrum
else
  f = [125 250 500 750 1000 1500 2000 3000 4000 6000 8000]; % Hz
  f_ht_siam = [250 500 1000 2000 4000 8000]; % Hz
  f_ul_siam = [500 1000 2000 4000]; % Hz
  switch id
    case 'normal'
    ht_siam = ff2ed(f_ht_siam,hl2spl(f_ht_siam,zeros(size(f_ht_siam)))); % Level at eardrum
    tin_siam = [-3.50 -2.00 2.00 4.50]; % Relative level to noise
    ht_ag = ff2ed(f,hl2spl(f,zeros(size(f)))); % Level at eardrum

    case 'listener01-l'
    %hl_siam = [14 16 20 31 65 78]; % Measured values
    ht_siam = [12.5 8.6 12.7 24.7 56.8 88.4]; % Level at eardrum
    tin_siam = [-0.50 4.00 5.00 8.00]; % Relative level to noise
    %hl_ag = [10 5 15 30 15 20 25 35 55 70 75]; % Measured values
    ht_ag = [30.6 16.1 20.9 35.4 19.7 28.1 35.5 44.4 64.3 81.2 88.3]; % Level at eardrum

    case 'listener02-r'
    %hl_siam = [65 72 80 90 90 88]; % Measured values
    ht_siam = [63.5 64.6 72.7 83.7 81.8 98.4]; % Level at eardrum
    tin_siam = [9.50 11.50 21.00 17.50]; % Relative level to noise
    %hl_ag = [40 55 65 70 70 80 85 80 75 85 95]; % Measured values
    ht_ag = [60.6 66.1 70.9 75.4 74.7 88.1 95.5 89.4 84.3 96.2 108.3]; % Level at eardrum

    case 'listener03-l'
    %hl_siam = [9 20 10 11 18 7]; % Measured values
    ht_siam = [7.5 12.6 2.7 4.7 9.8 17.4]; % Level at eardrum
    tin_siam = [-3.50 -3.00 2.50 5.50]; % Relative level to noise
    %hl_ag = [5 0 0 0 -5 -5 0 5 0 5 0]; % Measured values
    ht_ag = [25.6 11.1 5.9 5.4 -0.3 3.1 10.5 14.4 9.3 16.2 13.3]; % Level at eardrum

    case 'listener05-l'
    %hl_siam = [36 55 52 72 92 98]; % Measured values
    ht_siam = [34.5 47.6 44.7 65.7 83.8 108.4]; % Level at eardrum
    % 1kHz train 1.5dB but 1kHz measure 17.5 dB?
    tin_siam = [0.00 1.50 9.00 17.00]; % Relative level to noise
    %hl_ag = [10 20 35 35 50 60 75 75 80 90 105]; % Measured values
    ht_ag = [30.6 31.1 40.9 40.4 54.7 68.1 85.5 84.4 89.3 101.2 118.3]; % Level at eardrum

    case 'listener06-r'
    %hl_siam = [47 50 52 52 70 84]; % Measured values
    ht_siam = [45.5 42.6 44.7 45.7 61.8 94.4]; % Level at eardrum
    tin_siam = [1.00 3.50 5.00 7.00]; % Relative level to noise
    %hl_ag = [35 45 45 45 45 50 50 55 60 80 85]; % Measured values
    ht_ag = [55.6 56.1 50.9 50.4 49.7 58.1 60.5 64.4 69.3 91.2 98.3]; % Level at eardrum

    case 'listener07-l'
    %hl_siam = [20 28 36 46 59 96]; % Measured values
    ht_siam = [18.5 20.6 28.7 39.7 50.8 106.4]; % Level at eardrum
    tin_siam = [0.00 2.00 7.00 9.00]; % Relative level to noise
    %hl_ag = [15 20 30 35 35 35 40 45 45 60 70]; % Measured values
    ht_ag = [35.6 31.1 35.9 40.4 39.7 43.1 50.5 54.4 54.3 71.2 83.3]; % Level at eardrum

    case 'listener08-l'
    %hl_siam = [35 35 50 74 106 120]; % Measured values
    ht_siam = [33.5 27.6 42.7 67.7 97.8 130.4]; % Level at eardrum
    tin_siam = [-1.00 2.50 6.00 34.00]; % Relative level to noise
    %hl_ag = [20 25 30 35 40 55 65 80 95 105 105]; % Measured values
    ht_ag = [40.6 36.1 35.9 40.4 44.7 63.1 75.5 89.4 104.3 116.2 118.3]; % Level at eardrum

    case 'listener09-l'
    %hl_siam = [13 14 12 30 42 56]; % Measured values
    ht_siam = [11.5 6.6 4.7 23.7 33.8 66.4]; % Level at eardrum
    tin_siam = [2.00 1.00 4.00 11.00]; % Relative level to noise
    %hl_ag = [5 5 10 10 10 15 30 30 30 45 60]; % Measured values
    ht_ag = [25.6 16.1 15.9 15.4 14.7 23.1 40.5 39.4 39.3 56.2 73.3]; % Level at eardrum

    case 'listener10-l'
    %hl_siam = [12 16 12 10 14 10]; % Measured values
    ht_siam = [10.5 8.6 4.7 3.7 5.8 20.4]; % Level at eardrum
    % Drifting measurement at 4kHz
    tin_siam = [-3.50 -1.50 2.00 15.00]; % Relative level to noise
    %hl_ag = [5 5 5 5 5 0 0 0 0 5 10]; % Measured values
    ht_ag = [25.6 16.1 10.9 10.4 9.7 8.1 10.5 9.4 9.3 16.2 23.3]; % Level at eardrum

    case 'listener12-l'
    %hl_siam = [68 64 60 65 84 98]; % Measured values
    ht_siam = [66.5 56.6 52.7 58.7 75.8 108.4]; % Level at eardrum
    tin_siam = [7.00 5.00 9.50 17.00]; % Relative level to noise
    %hl_ag = [45 60 55 60 55 55 60 65 70 75 100]; % Measured values
    ht_ag = [65.6 71.1 60.9 65.4 59.7 63.1 70.5 74.4 79.3 86.2 113.3]; % Level at eardrum

    case 'listener14-r'
    % Strange jump at beginning at 4kHz
    %hl_siam = [33 42 56 72 90 88]; % Measured values
    ht_siam = [31.5 34.6 48.7 65.7 81.8 98.4]; % Level at eardrum
    tin_siam = [-3.00 1.50 6.00 22.00]; % Relative level to noise
    %hl_ag = [20 25 30 50 55 60 65 70 80 90 90]; % Measured values
    ht_ag = [40.6 36.1 35.9 55.4 59.7 68.1 75.5 79.4 89.3 101.2 103.3]; % Level at eardrum

    case 'listener15-r'
    %hl_siam = [35 39 41 54 104 120]; % Measured values
    ht_siam = [33.5 31.6 33.7 47.7 95.8 130.4]; % Level at eardrum
    tin_siam = [3.50 3.50 7.00 25.00]; % Relative level to noise
    %hl_ag = [25 20 30 30 35 45 55 85 90 90 100]; % Measured values
    ht_ag = [45.6 31.1 35.9 35.4 39.7 53.1 65.5 94.4 99.3 101.2 113.3]; % Level at eardrum

    case 'listener16-l'
    %hl_siam = [15 15 17 14 65 86]; % Measured values
    ht_siam = [13.5 7.6 9.7 7.7 56.8 96.4]; % Level at eardrum
    tin_siam = [-1.50 -1.00 2.00 12.00]; % Relative level to noise
    %hl_ag = [5 5 10 15 15 10 10 35 55 65 80]; % Measured values
    ht_ag = [25.6 16.1 15.9 20.4 19.7 18.1 20.5 44.4 64.3 76.2 93.3]; % Level at eardrum

    case 'listener17-r'
    %hl_siam = [16 14 18 21 30 54]; % Measured values
    ht_siam = [14.5 6.6 10.7 14.7 21.8 64.4]; % Level at eardrum
    tin_siam = [-3.50 -3.00 3.50 4.50]; % Relative level to noise
    %hl_ag = [15 10 10 10 10 10 15 15 25 40 45]; % Measured values
    ht_ag = [35.6 21.1 15.9 15.4 14.7 18.1 25.5 24.4 34.3 51.2 58.3]; % Level at eardrum

    case 'listener18-r'
    %hl_siam = [14 21 25 32 40 60]; % Measured values
    ht_siam = [12.5 13.6 17.7 25.7 31.8 70.4]; % Level at eardrum
    tin_siam = [0.00 1.00 6.00 12.00]; % Relative level to noise
    %hl_ag = [15 15 20 20 25 35 35 30 40 65 70]; % Measured values
    ht_ag = [35.6 26.1 25.9 25.4 29.7 43.1 45.5 39.4 49.3 76.2 83.3]; % Level at eardrum

    case 'listener19-r'
    %hl_siam = [36 42 42 45 66 94]; % Measured values
    ht_siam = [34.5 34.6 34.7 38.7 57.8 104.4]; % Level at eardrum
    tin_siam = [1.50 8.00 10.50 13.50]; % Relative level to noise
    %hl_ag = [30 35 35 35 35 40 45 45 55 70 80]; % Measured values
    ht_ag = [50.6 46.1 40.9 40.4 39.7 48.1 55.5 54.4 64.3 81.2 93.3 ]; % Level at eardrum
    
    case 'listener20-l'
    %hl_siam = [26 36 36 38 50 50]; % Measured values
    ht_siam = [24.5 28.6 28.7 31.7 41.8 60.4]; % Level at eardrum
    tin_siam = [-3.50 -1.00 1.00 6.50]; % Relative level to noise
    %hl_ag = [15 20 25 25 25 35 35 35 40 55 55]; % Measured values
    ht_ag = [35.6 31.1 30.9 30.4 29.7 43.1 45.5 44.4 49.3 66.2 68.3]; % Level at eardrum
    
    case 'listener21-l'
    %hl_siam = [57 58 58 66 86 120]; % Measured values
    ht_siam = [55.5 50.6 50.7 59.7 77.8 130.4]; % Level at eardrum
    % Strange drifting at 4 kHz
    tin_siam = [2.00 5.00 7.50 21.50]; % Relative level to noise
    %hl_ag = [45 50 50 55 55 55 65 70 70 75 95]; % Measured values
    ht_ag = [65.6 61.1 55.9 60.4 59.7 63.1 75.5 79.4 79.3 86.2 108.3]; % Level at eardrum

    otherwise
    error('listener not found');
  end

  % No hearing loss (default)
  ht = zeros(size(f));
  ul = ones(size(f));
  
  switch tolower(individualization)
    case 'ag' % Use hearing thresholds at eardrum derived from audiogram
      ht = ht_ag;

    case 'agl' % Same as 'ag' but with frequency resolution comparable to siam
      ht = interp1(f, ht_ag, f_ht_siam);
      ht = interp1(f_ht_siam, ht, f, 'linear', 'extrap');

    case 'a' % Use hearing thresholds from tone in quiet detection
      ht = interp1(f_ht_siam, ht_siam, f, 'linear', 'extrap');
      ht = max(0,min(130,ht));

    case {'ad','ada'} % Use both
      % Frequencies to interpolate.
      f = [125 250 500 750 1000 1500 2000 3000 4000 6000 8000]; % Hz

      % Frequencies of tone detection thresholds.
      f_ht_siam = [250 500 1000 2000 4000 8000]; % Hz

      % Frequencies of tone-in-noise detection thresholds.
      f_ul_siam = [500 1000 2000 4000]; % Hz

      % Tone-in-noise detection thresholds.
      % Example values for normal-hearing.
      tin_siam_nh = [-3.5 -2.0 2.0 4.5]; % Relative level to noise

      % We need to consider three cases:
      % 1) The TIN experiment was clearly supra-threshold (as intended)
      % 2) The TIN was clearly sub-threshold
      % 3) Something in between.
      
      % We will use the "normal hearing" thresholds as "separator"
      % between these cases.
      ul_siam_nh = tin2ul(f_ul_siam, tin_siam_nh);

      % Represent the tone detection levels in dB SPL at eardrum.
      tone_in_quiet_level = ht_siam;
      tone_in_noise_level = calcorr(f_ul_siam,tin_siam + 65);
      tone_in_noise_level_normal = calcorr(f_ul_siam,tin_siam_nh + 65);

      % Define a soft (continuous) criterion for which rule to apply:
      % 1) Tone-in-noise detection threshold more than 5 dB 
      % below normal-hearing tone-in-noise detection threshold
      % -> supra-threshold,
      % 2) Tone-in-quiet detection threshold more than 5 dB 
      % above normal-hearing tone-in-noise detection threshold 
      % -> sub-threshold,
      % 3) Interpolate between both to make the transition smooth.
      thresholdness = tone_in_quiet_level(2:end-1) - tone_in_noise_level_normal;
      criterion = interp1([-100;-5;0;5;100],[0;0;0.5;1;1], ...
        thresholdness, 'linear','extrap');
      
      % If requested, assume "normal" supra-threshold listening, i.e.
      % criterion == 1
      if strcmp(tolower(individualization),'ada')
        criterion = ones(size(criterion));
      end
        
      % Calculate a conservative maximum value
      % for the level uncertainty ul.
      % First calculate ul from tone-in-noise experiments.
      ul_noise = tin2ul(f_ul_siam, tin_siam);
      % Then calculate which values would be indicated
      % only by absolute hearing threshold.
      ul_quiet = tin2ul(f_ul_siam, tone_in_quiet_level(2:end-1) - 65);
      % Subtract any effect due to the absolute hearing threshold.
      ul_diff = ul_noise - (ul_quiet-1);

      % Use the criterion to make the transition between the estimates.
      % If the experiment was sub-threshold we can't separate ul and ht.
      % Hence, if the criterion is 1, ul_eff is ul of normal hearing.
      % Limit the maximum to 20 dB.
      ul_eff = tin2ul(f_ul_siam, tin_siam_nh).*criterion ...
        + min(20, ul_diff.*(1-criterion));    
            
      % Estimate the corresponding increase in tone detection threshold
      % due to the level uncertainty.
      dl_eff = max(0,ul2tin(f_ul_siam,ul_eff) ...
        - ul2tin(f_ul_siam,zeros(size(ul_eff))));

      % Calculate the effective hearing loss due to attenuation ONLY
      % by removing the estimated effect of the level uncertainty using
      % values from 500Hz and 4000Hz at 250Hz and 8000Hz, respectively.
      ht_eff = ht_siam - dl_eff([1,1:end,end]);

      % Interpolate the parameters that describe 
      % attenuation loss (ht_eff) and distiortion loss (ul_eff).
      ht = interp1(f_ht_siam, ht_eff, f, ...
        'linear', 'extrap');
      ul = interp1(f_ht_siam, ul_eff([1,1:end,end]), f, ...
        'linear', 'extrap');
      ul_nh = interp1(f_ht_siam, ul_siam_nh([1,1:end,end]), f, ...
        'linear', 'extrap');

      % Keep values in reasonable ranges.
      ht = max(0,min(130,ht));
      ul = max(ul_nh,min(20,ul));
    otherwise
      error('no such mode');
  end
end
