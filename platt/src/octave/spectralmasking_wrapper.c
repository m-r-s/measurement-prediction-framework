/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "constants.h"
#include "spectralmasking.c"

void mexFunction (int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
  plhs[0] = mxDuplicateArray(prhs[0]); // 1. spectralmask
  plhs[1] = mxDuplicateArray(prhs[1]); // 2. transmission
  plhs[2] = mxDuplicateArray(prhs[2]); // 3. spectralbuffer
  plhs[3] = mxDuplicateArray(prhs[3]); // 4. transmissionbuffer
  plhs[4] = mxDuplicateArray(prhs[4]); // 5. target

  float *spectralmask = (float*) mxGetData(plhs[0]);
  float *transmission = (float*) mxGetData(plhs[1]);
  float *spectralbuffer = (float*) mxGetData(plhs[2]);
  float *transmissionbuffer = (float*) mxGetData(plhs[3]);
  float *target = (float*) mxGetData(plhs[4]);

  spectralmasking(spectralmask,
                  transmission,
                  spectralbuffer,
                  transmissionbuffer,
                  target);
}


