/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

void
calculatelayers(float const * const maxima,
                float * const layerbuffer,
                float * const layers,
                int layer) {
  float const *window;
  int window_width;
  int temporal;
  switch(layer) {
    case 0:
      // layer 0 (copy)
      for (int i=0;i<NUMFILTERS;i++) {
        layers[i] = maxima[i];
      }
      return;
      break;
    case 1:
      window = hanning4;
      window_width = 3;
      temporal = 0;
      break;
    case 2:
      window = hanning8;
      window_width = 7;
      temporal = 0;
      break;
    case 3:
      window = hanning8;
      window_width = 7;
      temporal = 1;
      break;
    case 4:
      window = hanning16;
      window_width = 15;
      temporal = 1;
      break;
    case 5:
      window = hanning32;
      window_width = 31;
      temporal = 1;
      break;
  }
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
    float layer_tmp = 0.0;
    float window_norm = 0.0;
    for (int j=0;j<idx_stop;j++) {
      float window_tmp = window[o2];
      window_norm += window_tmp;
      layer_tmp += maxima[o1] * window_tmp;
      o1++;
      o2++;
    }
    layer_tmp /= window_norm;
    int o3 = i*2;
    float layer_old = layerbuffer[o3+1];
    layerbuffer[o3] = layer_old;
    layerbuffer[o3+1] = layer_tmp;
    if (temporal == 1) {
      layers[i] = 0.5*(layer_tmp + layer_old);
    } else {
      layers[i] = layer_tmp;
    }
  }
}

