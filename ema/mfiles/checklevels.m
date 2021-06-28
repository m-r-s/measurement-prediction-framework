function result = checklevels(s)
  rms_level=max(20*log10(rms(s)) + 130);
  peak_level=max(20*log10(max(abs(s))) + 130);
  result = (rms_level+peak_level < 200) && ( (rms_level<90 && peak_level<110) || (rms_level>=90 && peak_level<105) );
end
