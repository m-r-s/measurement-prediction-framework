void
filter(float const * const in,
         float * const out,
         float * const inputbuffer,
         float const * const impulseresponse,
         int const * const range,
         float const * const limit
        )
{ 
  int filtersamples = FILTERLENGTH*TICKSAMPLES;
  float limit_tmp = limit[0];
  float nlimit_tmp = -limit[0];
  
  // Copy new samples to the inputbuffer
  {
    int o1 = tickcount*TICKSAMPLES;
    for (int i=0;i<TICKSAMPLES;i++) {
      float in_tmp = in[i];
      if (in_tmp > limit_tmp) {
        inputbuffer[o1] = limit_tmp;
      } else if (in_tmp < nlimit_tmp) {
        inputbuffer[o1] = nlimit_tmp;
      } else {
        inputbuffer[o1] = in_tmp;
      }
      o1++;
    }
  }

  // Filter input
  {
    int o1 = tickcount*TICKSAMPLES;
    for (int i=0;i<TICKSAMPLES;i++) {
      float out_tmp = 0.0;
      // Determine integration ranges
      // Range in impulse response
      int start1 = range[0];
      int stop1 = range[1];
      // Range in buffer
      int start2 = (filtersamples+o1+i-start1)%filtersamples;
      int stop2 = (filtersamples+o1+i-stop1)%filtersamples;
      int o2 = start1;
      if (stop2 <= start2) {
        for (int j=start2;j>=stop2;j--) {
          out_tmp += inputbuffer[j] * impulseresponse[o2];
          o2++;
        }
      } else {
        for (int j=start2;j>=0;j--) {
          out_tmp += inputbuffer[j] * impulseresponse[o2];
          o2++;
        }
        for (int j=filtersamples-1;j>=stop2;j--) {
          out_tmp += inputbuffer[j] * impulseresponse[o2];
          o2++;
        }
      }
      // Save filtered value
      out[i] = out_tmp;
    }
  }
}
