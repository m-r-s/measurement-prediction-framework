/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "constants.h"
#include "mapbase.c"

void mexFunction (int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
  plhs[0] = mxDuplicateArray(prhs[0]); // 1. base
  plhs[1] = mxDuplicateArray(prhs[1]); // 2. gt
  plhs[2] = mxDuplicateArray(prhs[2]); // 3. target

  float *base = (float*) mxGetData(plhs[0]);
  float *gt = (float*) mxGetData(plhs[1]);
  float *target = (float*) mxGetData(plhs[2]);

  mapbase(base,
          gt,
          target);
}
