%% Hardware-related
% Configuration frequencies
cfg_freqs                = [  75  125  250  500 1000  2000 4000 8000 16000]; % Hz
% Input calibration
cfg_calib_in             = [ 130  130  130  130  130   130  130  130   130]; % dB SPL !!!
% Output calibration
cfg_calib_out            = [ 130  130  130  130  130   130  130  130   130]; % dB SPL !!!
% Limit for mapping working point and optional dynamic
cfg_speaker_maxlevel     = [ 100  100  100  100  100   100  100  100   100]; % dB SPL !!!

%% General variables
% Normal hearing threshold in dB SPL
cfg_normal_threshold     = [  32   21   10    4    2    -2   -5   12    12]; % dB SPL !!!
% "Normal" hearing uncomfortable level in dB SPL
cfg_normal_uncomfortable = [ 105  105  105  105  105   105  105  105   105]; % dB SPL !!!
% Levels that should be mapped above the hearing threshold if higher than this level
cfg_attention_threshold  = [  35   30   30   25   25    25   25   30    30]; % dB SPL !!!

%% Individual variables
% Hearing thresholds in dB SPL for left ear
cfg_threshold1           = [  50   50   50   50    50   50   50   50    50]-45; % dB SPL !!!
% Hearing thresholds in dB SPL for right ear
cfg_threshold2           = [  50   50   50   50    50   50   50   50    50]-45; % dB SPL !!!
% Uncomfortable level in dB SPL for left ear
cfg_uncomfortable1       = [  90   90   90   90    90   90   90   90    90]+15; % dB SPL !!!
% Uncomfortable level in dB SPL for left ear
cfg_uncomfortable2       = [  90   90   90   90    90   90   90   90    90]+15; % dB SPL !!!
% Transmission loss in dB for left ear
cfg_transmission1        = [   0    0    0    0     0    0    0    0     0]; % dB
% Transmission loss in dB for right ear
cfg_transmission2        = [   0    0    0    0     0    0    0    0     0]; % dB
% Dynamic expansion factor for left ear
cfg_expansion1           = [   1    1    1    1     1    1    1    1     1].*1; % dB/dB
% Dynamic expansion factor for right ear
cfg_expansion2           = [   1    1    1    1     1    1    1    1     1].*1; % dB/dB

%% Custom gain table (e.g., from openMHA)
% Rows: Gains for input levels in 1 dB steps, from 0 to 130 dB SPL
% Columns: Frequencies defined by gt_freqs
gt_freqs = [];
gt_data = [];


%% Tuning variables
% Guard intervals reserve some dynamic that is not used for mapping the operation point
guard_intervals = [0 6]; % [lower upper] dB

% Offsets the lowest operation point
threshold_offset = 3; % dB

% Max gain change rate limits energy leakage of side bands to other channels
max_gainrate = 24; % dB per period

% Spectral boost factor dB/dB can help to reduce spectral masking 
spectral_boost = 0.0;
