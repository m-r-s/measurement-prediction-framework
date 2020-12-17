/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "constants.h"
#include "gammatonemax.c"

void mexFunction (int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
  plhs[0] = mxDuplicateArray(prhs[0]); // 1. coeff
  plhs[1] = mxDuplicateArray(prhs[1]); // 2. calibration
  plhs[2] = mxDuplicateArray(prhs[2]); // 3. thresholds_shared
  plhs[3] = mxDuplicateArray(prhs[3]); // 4. in
  plhs[4] = mxDuplicateArray(prhs[4]); // 5. state
  plhs[5] = mxDuplicateArray(prhs[5]); // 6. buffer
  plhs[6] = mxDuplicateArray(prhs[6]); // 7. maxima
  plhs[7] = mxDuplicateArray(prhs[7]); // 8. age

  float *coeff = (float*) mxGetData(plhs[0]);
  float *calibration = (float*) mxGetData(plhs[1]);
  float *thresholds_normal = (float*) mxGetData(plhs[2]);
  float *in = (float*) mxGetData(plhs[3]);
  float *state = (float*) mxGetData(plhs[4]);
  float *buffer = (float*) mxGetData(plhs[5]);
  float *maxima = (float*) mxGetData(plhs[6]);
  int *age = (int*) mxGetData(plhs[7]);

  gammatonemax(coeff,
               calibration,
               thresholds_normal,
               in,
               state,
               buffer,
               maxima,
               age);
}



