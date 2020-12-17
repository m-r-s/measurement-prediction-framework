/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

void
adddynamic(float const * const difference,
           float const * const expansion,
           float * const spectralbuffer,
           float * const compressionbuffer,
           float * const compression,
           float const * const maxlevel,
           float const * const io,
           float * const target,
           int layer) {
  float const *window;
  int window_width;
  int expand, compress;
  switch(layer) {
    case 0:
      expand = 0;
      compress = 0;
      break;
    case 1:
      expand = 1;
      compress = 0;
      break;
    case 2:
      expand = 0;
      compress = 1;
      window = propagate_hanning4;
      window_width = 3;
      break;
    case 3:
      expand = 0;
      compress = 1;
      window = propagate_hanning6;
      window_width = 5;
      break;
    case 4:
      expand = 0;
      compress = 1;
      window = propagate_hanning12;
      window_width = 11;
      break;
  }

  // Load (and expand) differences, i.e., modulations
  if (expand < 1) {
    for (int i=0;i<NUMFILTERS;i++) {
      spectralbuffer[i] = difference[i];
    }
  } else {
    for (int i=0;i<NUMFILTERS;i++) {
      double partialgain_tmp = difference[i] * expansion[i];
      if (partialgain_tmp < MAXPARTIALGAIN){
        spectralbuffer[i] = partialgain_tmp;
      } else {
        spectralbuffer[i] = MAXPARTIALGAIN;
      }
    }
  }
  if (compress < 1) {
    for (int i=0;i<NUMFILTERS;i++) {
      target[i] += spectralbuffer[i];
    }
  } else {
    // Check and quantify violation of rules
    int o1 = 2;
    for (int i=0;i<NUMFILTERS;i++) {
      float violation_tmp, compression_tmp;
      float level_tmp = spectralbuffer[i];
      // Get current dynamic
      if (level_tmp > COMPRESSIONMARGIN) {
        violation_tmp = target[i] + level_tmp - COMPRESSIONMARGIN - maxlevel[i];
        if (violation_tmp < 0.0) {
          violation_tmp = 0.0;
        }
        compression_tmp = (level_tmp-violation_tmp)/level_tmp;
        if (compression_tmp < 0.0 ) {
          compression_tmp = 0.0;
        }
      } else if (level_tmp < -COMPRESSIONMARGIN) {
        violation_tmp = target[i] + level_tmp + COMPRESSIONMARGIN - io[o1];
        if (violation_tmp > 0.0) {
          violation_tmp = 0.0;
        }
        compression_tmp = (level_tmp-violation_tmp)/level_tmp;
        if (compression_tmp < 0.0 ) {
          compression_tmp = 0.0;
        }
      } else {
        compression_tmp = 1.0;
      }
      compressionbuffer[i] = compression_tmp;
      o1 += 4;
    }

    // Propagate minimum compression
    for (int i=0;i<NUMFILTERS;i++) {
      int o1, o2;
      if (i < window_width) {
        o1 = 0;
        o2 = window_width-i;
      } else {
        o1 = i-window_width;
        o2 = 0;
      }
      int idx_stop = window_width*2+1;
      if (o1+idx_stop > NUMFILTERS) {
        idx_stop = NUMFILTERS-o1;
      }
      if (o2+idx_stop > window_width*2+1) {
        idx_stop = (window_width*2+1)-o2;
      }
      float minimum_tmp = 1.0;
      // HOTSPOT on Rasperry Pi 3!
      for (int j=0;j<idx_stop;j++) {
        float propagate_tmp = compressionbuffer[o1] + window[o2];
        if (propagate_tmp < minimum_tmp) {
          minimum_tmp = propagate_tmp;
        }
        o1++;
        o2++;
      }
      compression[i] = minimum_tmp;
    }
   
    // Apply compression and add dynamic
    for (int i=0;i<NUMFILTERS;i++) {
      target[i] += spectralbuffer[i] * compression[i];
    }
  }
}
