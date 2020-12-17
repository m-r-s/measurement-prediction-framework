% Write center frequencies to file
fp = fopen('../src/configuration/freqs.bin','wb');
fwrite(fp,freqs,'single');
fclose(fp);

% Write gammatone filter bank coefficients to file
fp = fopen('../src/configuration/coeff.bin','wb');
fwrite(fp,coeff,'single');
fclose(fp);

% Write calibration to file
fp = fopen('../src/configuration/calibration.bin','wb');
fwrite(fp,calibration,'single');
fclose(fp);

% Write spectral masks to file
fp = fopen('../src/configuration/spectralmask.bin','wb');
fwrite(fp,spectralmask,'single');
fclose(fp);

% Write left input output mapping to file
fp = fopen('../src/configuration/io_left.bin','wb');
fwrite(fp,io_left,'single');
fclose(fp);

% Write right input output mapping to file
fp = fopen('../src/configuration/io_right.bin','wb');
fwrite(fp,io_right,'single');
fclose(fp);

% Write left gain table to file
fp = fopen('../src/configuration/gt_left.bin','wb');
fwrite(fp,gt_left,'single');
fclose(fp);

% Write right gain table to file
fp = fopen('../src/configuration/gt_right.bin','wb');
fwrite(fp,gt_right,'single');
fclose(fp);

% Write left expansion to file
fp = fopen('../src/configuration/expansion_left.bin','wb');
fwrite(fp,expansion_left,'single');
fclose(fp);

% Write right expansion to file
fp = fopen('../src/configuration/expansion_right.bin','wb');
fwrite(fp,expansion_right,'single');
fclose(fp);

% Write normal hearing thresholds to file
fp = fopen('../src/configuration/thresholds_normal.bin','wb');
fwrite(fp,thresholds_normal,'single');
fclose(fp);

% Write normal uncomfortable thresholds to file
fp = fopen('../src/configuration/uncomfortable_normal.bin','wb');
fwrite(fp,uncomfortable_normal,'single');
fclose(fp);

% Write left mute channels to file
fp = fopen('../src/configuration/maxlevel_left.bin','wb');
fwrite(fp,maxlevel_left,'single');
fclose(fp);

% Write right mute channels to file
fp = fopen('../src/configuration/maxlevel_right.bin','wb');
fwrite(fp,maxlevel_right,'single');
fclose(fp);

% Write left mute channels to file
fp = fopen('../src/configuration/mute_left.bin','wb');
fwrite(fp,mute_left,'single');
fclose(fp);

% Write right mute channels to file
fp = fopen('../src/configuration/mute_right.bin','wb');
fwrite(fp,mute_right,'single');
fclose(fp);

% Write left transmission loss to file
fp = fopen('../src/configuration/transmission_left.bin','wb');
fwrite(fp,transmission_left,'single');
fclose(fp);

% Write right transmission loss to file
fp = fopen('../src/configuration/transmission_right.bin','wb');
fwrite(fp,transmission_right,'single');
fclose(fp);

% Write gainrate to file
fp = fopen('../src/configuration/gainrate.bin','wb');
fwrite(fp,gainrate,'single');
fclose(fp);

