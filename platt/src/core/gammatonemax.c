/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

void
gammatonemax(float const * const coeff,
             float const * const calibration,
             float const * const thresholds_normal,
             float const * const in,
             float * const state,
             float * const buffer,
             float * const maxima,
             int * const age)
{
  for (int i=0; i<NUMFILTERS; i++) {

    // Restore filter state
    {
      int o1 = i*(2*TICKSIZE); // offset for buffer
      int o2 = i*(2*ORDER); // offset for state
      for (int j=0; j<(2*ORDER); j+=2) {
        buffer[o1+j] = state[o2+j]; // real part
        buffer[o1+j+1] = state[o2+j+1]; // imaginary part
      }
    }

    // Load filter coefficients
    float b0r_tmp, b0i_tmp, a1r_tmp, a1i_tmp, a1in_tmp;
    {
      int o1 = i*4;
      b0r_tmp = coeff[o1];
      b0i_tmp = coeff[o1+1];
      a1r_tmp = coeff[o1+2];
      a1i_tmp = coeff[o1+3];
      a1in_tmp = -a1i_tmp;
    }

    // Initialize maxima
    float max_tmp = 0.0;
    
    // Perform filtering
    {
      int o1 = i*(2*TICKSIZE) + (2*ORDER); // start sample for buffer
      float tmp_real, tmp_imag;
  	  for (int j=0; j<TICKSAMPLES; j++) {
        // Apply phase and gain of b0 to real values input signal
        tmp_real = in[j];
        buffer[o1] = b0r_tmp*tmp_real;
        buffer[o1+1] = b0i_tmp*tmp_real;
        // And add the recursive parts (loop unrolled)
        // First order
        tmp_real = buffer[o1-2];
        tmp_imag = buffer[o1-1];
        buffer[o1] += a1r_tmp*tmp_real + a1in_tmp*tmp_imag;
        buffer[o1+1] += a1i_tmp*tmp_real + a1r_tmp*tmp_imag;
        // Second order
        tmp_real = buffer[o1-4];
        tmp_imag = buffer[o1-3];
        buffer[o1-2] += a1r_tmp*tmp_real + a1in_tmp*tmp_imag;
        buffer[o1-1] += a1i_tmp*tmp_real + a1r_tmp*tmp_imag;
        // Third order
        tmp_real = buffer[o1-6];
        tmp_imag = buffer[o1-5];
        buffer[o1-4] += a1r_tmp*tmp_real + a1in_tmp*tmp_imag;
        buffer[o1-3] += a1i_tmp*tmp_real + a1r_tmp*tmp_imag;
        // Fourth order
        tmp_real = buffer[o1-8];
        tmp_imag = buffer[o1-7];
        buffer[o1-6] += a1r_tmp*tmp_real + a1in_tmp*tmp_imag;
        buffer[o1-5] += a1i_tmp*tmp_real + a1r_tmp*tmp_imag;

        // Get the maximum amplitude values (only from real part)
        if (tmp_real>max_tmp) {
          max_tmp = tmp_real;
        }
        o1 += 2; // Next sample
      }
    }

    // Lowest amplitude allowed before conversion to dB
    if (max_tmp < 0.00000001) {
      max_tmp = 0.00000001;
    }

    // Convert to dB and calibrate
    max_tmp = LOG2DB*log(max_tmp) + calibration[2*i];

    // Initial masking
    {
      // Determine the new maximum amplitude values (includes temporal masking)
      float max_old, max_new;
      max_old = maxima[i];
      if (max_tmp >= max_old) {
        max_new = max_tmp;
        age[i] = 0;
      } else if (age[i] < MAXHOLDTICKS) {
        max_new = max_old;
        age[i]++;
      } else {
        max_new = max_old - MAXDECAY;
      }

      // Ignore levels below threshold
      {
        float threshold_tmp = thresholds_normal[i];
        if (max_new < threshold_tmp) {
          max_new = threshold_tmp;
        }
      }

      maxima[i] = max_new;
    }

    // Store filter state
    {
      int o1 = i*(2*ORDER);
      int o2 = i*(2*TICKSIZE) + (2*TICKSAMPLES);
      for (int j=0; j<(2*ORDER); j+=2) {
        state[o1+j] = buffer[o2+j];
        state[o1+j+1] = buffer[o2+j+1];
      }
    }
  }
}

