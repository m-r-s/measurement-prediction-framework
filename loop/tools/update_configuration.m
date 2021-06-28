#!/usr/bin/octave -q
close all
clear
clc

% Advertise that the calibration must be checked
error('please check your calibration');

fs = 48000;

calibration = 5; % dB gain to theoretically achieve 130 dB SPL with an RMS of 1 at 1000 Hz.

hardclip = 105; % dB SPL

freq  = [   0  125  250  500  750 1000 1500 2000 3000 4000 6000 8000 10000 12000 14000 24000];
gain1 = [ 4.0  4.0  4.5  2.5  1.5  0.0 -5.0 -4.5 -6.5 -5.0 -3.0 -3.0  -6.5  -9.0  -8.5  -8.5];
gain2 = [ 4.0  4.0  4.5  2.5  1.5  0.0 -5.0 -4.5 -6.5 -5.0 -3.0 -3.0  -6.5  -9.0  -8.5  -8.5];
% Corrections according to Kemar artificial head (measured at eardrum microphone)
kemar1 =[ 0.0  2.0 -1.0 -2.0 -2.0 -3.0 -1.0 -9.0 -13.0 -10.0 -2.0 0.0  6.0   3.0   2.0   0.0];
kemar2 =[ 0.0  7.0  1.0 -4.0 -4.0 -3.0 -2.0 -9.0 -15.0 -9.0   0.0 2.0  6.0   5.0   7.0   0.0];
kemar_mean = mean([kemar1;kemar2])
gain1 = gain1 - kemar_mean;
gain2 = gain2 - kemar_mean;

% Calculate compensation filter coefficients
max_range = 20.*48; % samples
ir1 = zeros(max_range,1);
ir2 = zeros(max_range,1);

num_coeff = 46; % samples
num_bands = length(freq);
idx = vertcat([1:num_bands-1;2:num_bands]);
idx = idx(:).';
ir1_tmp = firls(num_coeff, freq(idx)./(fs/2), 10.^(-gain1(idx)./20));
ir2_tmp = firls(num_coeff, freq(idx)./(fs/2), 10.^(-gain2(idx)./20));
ir1(1:length(ir1_tmp)) = ir1_tmp .* 10.^(calibration./20);
ir2(1:length(ir2_tmp)) = ir2_tmp .* 10.^(calibration./20);

function range = selectmain(in,level)
  min_level = 10.^(level/20);
  [~, maxidx] =  max(abs(in));
  start = find(abs(in)>min_level,1,'first');
  stop = find(abs(in)>min_level,1,'last');
  if isempty(start)
    start = maxidx;
  end
  if isempty(stop)
    stop = maxidx;
  end
  range = [start stop];
end

level1 = 0;
while diff(selectmain(ir1,level1)) <= max_range && level1 >= -100
  level1 = level1 - 1;
end
level1 = level1 + 1;

level2 = 0;
while diff(selectmain(ir2,level2)) <= max_range && level2 >= -100
  level2 = level2 - 1;
end
level2 = level2 + 1;

ir1 = single(ir1);
ir2 = single(ir2);

range1 = int32(selectmain(ir1,level1)-1);
range2 = int32(selectmain(ir2,level2)-1);

limit = single(10.^((hardclip-130)./20));


printf('ir1 = [');
printf('%.15f ', ir1(range1(1)+1:range1(2)+1));
printf('];\n');
printf('ir2 = [');
printf('%.15f ', ir2(range2(1)+1:range2(2)+1));
printf('];\n');
% Write coefficients and ranges to files
fp = fopen('../src/configuration/impulseresponse1.bin','wb');
fwrite(fp,ir1,'single');
fclose(fp);
fp = fopen('../src/configuration/impulseresponse2.bin','wb');
fwrite(fp,ir2,'single');
fclose(fp);
fp = fopen('../src/configuration/range1.bin','wb');
fwrite(fp,range1,'int32');
fclose(fp);
fp = fopen('../src/configuration/range2.bin','wb');
fwrite(fp,range2,'int32');
fclose(fp);
fp = fopen('../src/configuration/limit.bin','wb');
fwrite(fp,limit,'single');
fclose(fp);


[~, maxidx1] = max(abs(ir1));
[~, maxidx2] = max(abs(ir2));

printf("latency1 = %.2fms\nlatency2 = %.2fms\n",(maxidx1-1).*1000./fs,(maxidx1-1).*1000./fs);
printf("range1 = [%i %i]\nrange2 = [%i %i]\n",range1(1),range1(2),range2(1),range2(2));
printf("limit = %f\n",limit);

printf('done\n');
