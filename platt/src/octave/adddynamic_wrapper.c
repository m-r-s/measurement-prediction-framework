/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "constants.h"
#include "adddynamic.c"

void mexFunction (int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
  plhs[0] = mxDuplicateArray(prhs[0]); // 1. difference
  plhs[1] = mxDuplicateArray(prhs[1]); // 2. expansion
  plhs[2] = mxDuplicateArray(prhs[2]); // 3. spectralbuffer
  plhs[3] = mxDuplicateArray(prhs[3]); // 4. compressionbuffer
  plhs[4] = mxDuplicateArray(prhs[4]); // 5. compression
  plhs[5] = mxDuplicateArray(prhs[5]); // 6. maxlevel
  plhs[6] = mxDuplicateArray(prhs[6]); // 7. io
  plhs[7] = mxDuplicateArray(prhs[7]); // 8. target
  int *layer = (int*) mxGetData(prhs[8]); // 9. layer

  float *difference = (float*) mxGetData(plhs[0]);
  float *expansion = (float*) mxGetData(plhs[1]);
  float *spectralbuffer = (float*) mxGetData(plhs[2]);
  float *compressionbuffer = (float*) mxGetData(plhs[3]);
  float *compression = (float*) mxGetData(plhs[4]);
  float *maxlevel = (float*) mxGetData(plhs[5]);
  float *io = (float*) mxGetData(plhs[6]);
  float *target = (float*) mxGetData(plhs[7]);

  adddynamic(difference,
             expansion,
             spectralbuffer,
             compressionbuffer,
             compression,
             maxlevel,
             io,
             target,
             layer[0]);
}

