/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "constants.h"
#include "resynthesis.c"

void mexFunction (int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
  plhs[0] = mxDuplicateArray(prhs[0]); // 1. calibration
  plhs[1] = mxDuplicateArray(prhs[1]); // 2. gainrate
  plhs[2] = mxDuplicateArray(prhs[2]); // 3. buffer
  plhs[3] = mxDuplicateArray(prhs[3]); // 4. reference
  plhs[4] = mxDuplicateArray(prhs[4]); // 5. target
  plhs[5] = mxDuplicateArray(prhs[5]); // 6. gain
  plhs[6] = mxDuplicateArray(prhs[6]); // 7. out

  float *calibration = (float*) mxGetData(plhs[0]);
  float *gainrate = (float*) mxGetData(plhs[1]);
  float *buffer = (float*) mxGetData(plhs[2]);
  float *reference = (float*) mxGetData(plhs[3]);
  float *target = (float*) mxGetData(plhs[4]);
  float *gain = (float*) mxGetData(plhs[5]);
  float *out = (float*) mxGetData(plhs[6]);

  resynthesis(calibration,
              gainrate,
              buffer,
              reference,
              target,
              gain,
              out);
}

