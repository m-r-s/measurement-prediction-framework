/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

void
resynthesis( float const * const calibration,
             float const * const gainrate,
             float * const buffer,
             float const * const reference,
             float const * const target,
             float * const gain,
             float * const out)
{
  // Initialize with zeros
  for (int i=0; i<TICKSAMPLES; i++) {
    out[i] = 0.0;
  }

  int o1 = 0;
  for (int i=0; i<NUMFILTERS; i++) {
    float amp_tmp, amp_diff;
    {
      float gain_last = gain[i];
      float gain_diff;
      { 
        gain_diff = GAINCORRECTION + target[i] - reference[i] +  calibration[o1] - calibration[o1+1] - gain_last;
        float gainrate_tmp = gainrate[i];

        // Limit gain changes to avoid cross-talk
        if (gain_diff > gainrate_tmp) {
          gain_diff = gainrate_tmp;
        } else if (gain_diff < -gainrate_tmp) {
          gain_diff = -gainrate_tmp;
        }
        gain[i] += gain_diff;
      }
      amp_tmp = exp(gain_last/LOG2DB);
      amp_diff = (exp((gain_last+gain_diff)/LOG2DB) - amp_tmp)/TICKSAMPLES;
    }
    o1 += 2;
    {
      int o2 = i*(2*TICKSIZE);
      for (int j=0; j<TICKSAMPLES; j++) {
        amp_tmp += amp_diff;
        out[j] += buffer[o2] * amp_tmp;
        o2 += 2;
      }
    }
  }
}
