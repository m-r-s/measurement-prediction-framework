/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

void
spectralmasking(float const * const spectralmask,
                float const * const transmission,
                float * const spectralbuffer,
                float * const transmissionbuffer,
                float * const target) {
  for (int i=0;i<NUMFILTERS;i++) {
    transmissionbuffer[i] = target[i] - transmission[i];
  }
  for (int i=0;i<NUMFILTERS;i++) {
    float max_mask = -100.0;
    int o1 = NUMFILTERS-1-i;
    for (int j=0;j<NUMFILTERS;j++) {
      float mask_tmp = spectralmask[o1] + transmissionbuffer[j];
      if (mask_tmp > max_mask) {
        max_mask = mask_tmp;
      }
      o1++;
    }
    spectralbuffer[i] = max_mask + transmission[i];
  }
  for (int i=0;i<NUMFILTERS;i++) {
    target[i] = spectralbuffer[i];
  }
}

