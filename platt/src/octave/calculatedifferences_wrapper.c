/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "constants.h"
#include "calculatedifferences.c"

void mexFunction (int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
  plhs[0] = mxDuplicateArray(prhs[0]); // 1. layers_ref
  plhs[1] = mxDuplicateArray(prhs[1]); // 2. layers_diff
  plhs[2] = mxDuplicateArray(prhs[2]); // 3. differences

  float *layers_ref = (float*) mxGetData(plhs[0]);
  float *layers_diff = (float*) mxGetData(plhs[1]);
  float *differences = (float*) mxGetData(plhs[2]);

  calculatedifferences(layers_ref,
                       layers_diff,
                       differences);
}
