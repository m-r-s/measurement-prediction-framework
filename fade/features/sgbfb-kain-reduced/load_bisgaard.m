function [f, hl] = load_bisgaard(number)

f = [125   250   375   500   750  1000  1500  2000  3000  4000  6000  8000];

hearingloss = [  ...
         0     0     0     0     0     0     0     0     0     0     0     0; ... % N0
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
      ];

hl = hearingloss(number+1,:);
