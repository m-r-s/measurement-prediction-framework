/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

void
checkmaxlevels( float const * const mute,
                float const * const  maxlevel,                
                float * const target) {
  for (int i=0;i<NUMFILTERS;i++) {
    if (mute[i] >= 1.0) {
      target[i] = -100.0;
    } else if (target[i] > maxlevel[i]) {
      target[i] = maxlevel[i];
    }
  }
}

