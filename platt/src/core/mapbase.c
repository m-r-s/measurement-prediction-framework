/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

void
mapbase(float const * const base,
        float const * const gt,
        float *target) {
  int o1 = 0;
  for (int i=0;i<NUMFILTERS;i++) {
    float base_tmp = base[i];
    base_tmp -= (float) GTMIN;
    if (base_tmp < 0) {
      base_tmp = 0.0;
    } else if (base_tmp > (float) (GTLEVELS-2)) {
      base_tmp = (float) (GTLEVELS-2);
    }
    int o2 = (int) (base_tmp);
    float weight = base_tmp - (float) o2;
    int o3 = o1 + o2;
    target[i] = base[i] + gt[o3]*(1-weight) + gt[o3+1]*weight;
    o1 += GTLEVELS;
  }
}
