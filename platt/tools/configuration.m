%% Hardware-related
% Configuration frequencies: sprintf('%.1f ',1000*2.^(-4:0.5:4))
cfg_freqs                = [  62.5  88.4  125.0 176.8 250.0 353.6 500.0 707.1 1000.0 1414.2 2000.0 2828.4 4000.0 5656.9 8000.0 11313.7 16000.0]; % Hz
% Input calibration
cfg_calib_in             = [   130   130    130   130   130   130   130   130    130    130    130    130    130    130    130     130     130]; % dB SPL !!!
% Output calibration
cfg_calib_out            = [ 129.9 129.9  130.0 130.1 129.9 129.6 129.0 128.2  127.7  125.9  120.8  118.2  120.5  120.2  118.9   129.9   137.8]; % dB SPL !!!
%cfg_calib_out            = [   130   130    130   130   130   130   130   130    130    130    130    130    130    130    130     130     130]; % dB SPL @ MIC!!!
% Limit for mapping working point and optional dynamic
cfg_speaker_maxlevel     = [   130   130    130   130   130   130   130   130    130    130    130    130    130    130    130     130     130]; % dB SPL @ MIC!!!

%% General variables
% Normal hearing threshold in dB SPL free field (from ISO226 Loudness Curves)
cfg_normal_threshold     = [  35.3  27.4   21.3  16.1  12.3   9.0   6.4   5.1    5.2    4.9    1.3   -1.7   -3.1    4.3   15.2    12.9    27.3]; % dB SPL !!! (Robinson-Dadson (1956) audible)
% "Normal" hearing uncomfortable level in dB SPL
cfg_normal_uncomfortable = [ 116.9 114.1  112.1 110.3 109.0 108.4 107.9 109.8  110.2  109.1  104.6   99.1   97.2  105.4  116.3   118.4   124.4]; % dB SPL !!! (Robinson-Dadson (1956) 110phon)
% Levels that should be mapped above the hearing threshold if higher than this level
cfg_attention_threshold  = [  53.2  47.3   42.1  36.9  32.7  30.0  28.4  28.9   29.9   30.0   28.4   25.1   22.6   28.3   38.0    35.0    46.5]; % dB SPL !!! (Robinson-Dadson (1956) 30phon)

% Input from SIAM threshold measurements
siam_sweep_freqs = [250 500 1000 2000 4000 6000]; % in Hz
siam_sweep_thresholds_left = [0.0 0.0 0.0 0.0 0.0 0.0 ];
siam_sweep_thresholds_right = [0.0 0.0 0.0 0.0 0.0 0.0 ];

expansion_factor = 1;

%% Individual variables
% Hearing thresholds in dB SPL for left ear
%cfg_threshold1           = [    50    50    50     50    50    50    50    50     50     50     50     50     50     50     50      50      50]-45; % dB SPL @ MIC!!!
cfg_threshold1 = interp1([0 siam_sweep_freqs 24000], siam_sweep_thresholds_left([1 1:end end]), cfg_freqs, 'linear') + (cfg_calib_out - cfg_calib_in); % dB SPL @ MIC!!!
% Hearing thresholds in dB SPL for right ear
%cfg_threshold2           = [    50    50    50     50    50    50    50    50     50     50     50     50     50     50     50      50      50]-45; % dB SPL @ MIC!!!
cfg_threshold2 = interp1([0 siam_sweep_freqs 24000], siam_sweep_thresholds_right([1 1:end end]), cfg_freqs, 'linear') + (cfg_calib_out - cfg_calib_in); % dB SPL @ MIC!!!
% Uncomfortable level in dB SPL for left ear
cfg_uncomfortable1       = cfg_normal_uncomfortable; % dB SPL @ MIC!!!
% Uncomfortable level in dB SPL for left ear
cfg_uncomfortable2       = cfg_normal_uncomfortable; % dB SPL @ MIC!!!
% Transmission loss in dB for left ear
cfg_transmission1        = [     0     0     0      0     0     0     0     0      0      0      0      0      0      0      0       0       0]; % dB
% Transmission loss in dB for right ear
cfg_transmission2        = [     0     0     0      0     0     0     0     0      0      0      0      0      0      0      0       0       0]; % dB
% Dynamic expansion factor for left ear
cfg_expansion1           = [     1     1     1      1     1     1     1     1      1      1      1      1      1      1      1       1       1].*expansion_factor; % dB/dB
% Dynamic expansion factor for right ear
cfg_expansion2           = [     1     1     1      1     1     1     1     1      1      1      1      1      1      1      1       1       1].*expansion_factor; % dB/dB

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
