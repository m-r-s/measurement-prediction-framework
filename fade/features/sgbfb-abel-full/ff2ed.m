function y = ff2ed(f, x)
% Free field to eardrum transformation values digitized from [1].
% [1] Shaw, E. A. G., & Vaillancourt, M. M. (1985). Transformation of sound‐pressure level from the free field to the eardrum presented in numerical form. The Journal of the Acoustical society of America, 78(3), 1120-1123.
frequencies   = [0.2 0.25 0.3 0.32 0.4 0.5 0.6 0.63 0.7 0.8 0.9 1.0 1.2 1.25 1.4 ...
                 1.6 1.8 2.0 2.3 2.5 2.7 2.9 3.0 3.2 3.5 4.0 4.5 5.0 5.5 6.0 ...
                 6.3 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 10.5 11.0 11.5 12.0];
values = [0.5 1.0 1.3 1.4 1.5 1.8 2.3 2.4 2.8 3.1 3.0 2.6 2.7 3.0 4.1 ...
          6.1 9.0 12.0 15.9 16.8 16.8 15.8 15.4 14.9 14.7 14.3 12.8 10.7 8.9 7.3 ...
          6.4 5.8 4.3 3.1 1.8 0.5 -0.6 -1.7 -1.7 2.5 6.8 8.4 8.5];
y = x+interp1(frequencies,values,f./1000,'linear','extrap');
end
