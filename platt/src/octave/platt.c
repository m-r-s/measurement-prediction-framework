/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "constants.h"
#include "variables.h"
#include "gammatonemax.c"
#include "calculatelayers.c"
#include "calculatedifferences.c"
#include "mapbase.c"
#include "checkmaxlevels.c"
#include "spectralmasking.c"
#include "adddynamic.c"
#include "resynthesis.c"
#include "tick.c"

void mexFunction (int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
  FILE *fp;

  // Load GAMMATONE CENTER FREQUENCIES
  for (int i=0; i<NUMFILTERS; i++) {
    freqs[i] = 0.0;
  }
  fp = fopen("configuration/freqs.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/freqs.bin'\n");
    return;
  }
  fread(freqs,sizeof(freqs),1,fp);
  fclose(fp);

  // Load GAMMATONE FILTER COEFFICIENTS
  for (int i=0; i<4*NUMFILTERS; i++) {
    coeff[i] = 0.0;
  }
  fp = fopen("configuration/coeff.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/coeff.bin'\n");
    return;
  }
  fread(coeff,sizeof(coeff),1,fp);
  fclose(fp);

  // Load CALIBRATION
  for (int i=0; i<2*NUMFILTERS; i++) {
    calibration[i] = 0.0;
  }
  fp = fopen("configuration/calibration.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/calibration.bin'\n");
    return;
  }
  fread(calibration,sizeof(calibration),1,fp);
  fclose(fp);

  // Load SPECTRAL MASKING
  for (int i=0; i<NUMFILTERS*2-1; i++) {
    spectralmask[i] = 0.0;
  }
  fp = fopen("configuration/spectralmask.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/spectralmask.bin'\n");
    return;
  }
  fread(spectralmask,sizeof(spectralmask),1,fp);
  fclose(fp);
  for (int i=0; i<NUMFILTERS; i++) {
    spectralbuffer[i] = 0.0;
  }

  // Load LEFT IO
  for (int i=0; i<4*NUMFILTERS; i++) {
    io1[i] = 0.0;
  }
  fp = fopen("configuration/io_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/io_left.bin'\n");
    return;
  }
  fread(io1,sizeof(io1),1,fp);
  fclose(fp);

  // Load RIGHT IO
  for (int i=0; i<4*NUMFILTERS; i++) {
    io2[i] = 0.0;
  }
  fp = fopen("configuration/io_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/io_right.bin'\n");
    return;
  }
  fread(io2,sizeof(io2),1,fp);
  fclose(fp);

  // Load LEFT GT
  for (int i=0; i<(NUMFILTERS*GTLEVELS); i++) {
    gt1[i] = 0.0;
  }
  fp = fopen("configuration/gt_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/gt_left.bin'\n");
    return;
  }
  fread(gt1,sizeof(gt1),1,fp);
  fclose(fp);

  // Load RIGHT GT
  for (int i=0; i<(NUMFILTERS*GTLEVELS); i++) {
    gt2[i] = 0.0;
  }
  fp = fopen("configuration/gt_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/gt_right.bin'\n");
    return;
  }
  fread(gt2,sizeof(gt2),1,fp);
  fclose(fp);

  // Load LEFT EXPANSION
  for (int i=0; i<NUMFILTERS; i++) {
    expansion1[i] = 0.0;
  }
  fp = fopen("configuration/expansion_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/expansion_left.bin'\n");
    return;
  }
  fread(expansion1,sizeof(expansion1),1,fp);
  fclose(fp);

  // Load RIGHT EXPANSION
  for (int i=0; i<NUMFILTERS; i++) {
    expansion2[i] = 0.0;
  }
  fp = fopen("configuration/expansion_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/expansion_right.bin'\n");
    return;
  }
  fread(expansion2,sizeof(expansion2),1,fp);
  fclose(fp);

  // Load NORMAL HEARING THRESHOLDS
  for (int i=0; i<NUMFILTERS; i++) {
    thresholds_normal[i] = 0.0;
  }
  fp = fopen("configuration/thresholds_normal.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/thresholds_normal.bin'\n");
    return;
  }
  fread(thresholds_normal,sizeof(thresholds_normal),1,fp);
  fclose(fp);

  // Load NORMAL UNCOMFORTABLE LEVEL
  for (int i=0; i<NUMFILTERS; i++) {
    uncomfortable_normal[i] = 0.0;
  }
  fp = fopen("configuration/uncomfortable_normal.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/uncomfortable_normal.bin'\n");
    return;
  }
  fread(uncomfortable_normal,sizeof(uncomfortable_normal),1,fp);
  fclose(fp);

  // Load LEFT MAXLEVEL
  for (int i=0; i<NUMFILTERS; i++) {
    maxlevel1[i] = 0.0;
  }
  fp = fopen("configuration/maxlevel_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/maxlevel_left.bin'\n");
    return;
  }
  fread(maxlevel1,sizeof(maxlevel1),1,fp);
  fclose(fp);

  // Load RIGHT MAXLEVEL
  for (int i=0; i<NUMFILTERS; i++) {
    maxlevel2[i] = 0.0;
  }
  fp = fopen("configuration/maxlevel_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/maxlevel_right.bin'\n");
    return;
  }
  fread(maxlevel2,sizeof(maxlevel2),1,fp);
  fclose(fp);

  // Load LEFT MUTE CHANNELS
  for (int i=0; i<NUMFILTERS; i++) {
    mute1[i] = 0.0;
  }
  fp = fopen("configuration/mute_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/mute_left.bin'\n");
    return;
  }
  fread(mute1,sizeof(mute1),1,fp);
  fclose(fp);

  // Load RIGHT MUTE CHANNELS
  for (int i=0; i<NUMFILTERS; i++) {
    mute2[i] = 0.0;
  }
  fp = fopen("configuration/mute_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/mute_right.bin'\n");
    return;
  }
  fread(mute2,sizeof(mute2),1,fp);
  fclose(fp);

  // Load LEFT TRANSMISSION
  for (int i=0; i<NUMFILTERS; i++) {
    transmission1[i] = 0.0;
  }
  fp = fopen("configuration/transmission_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/transmission_left.bin'\n");
    return;
  }
  fread(transmission1,sizeof(transmission1),1,fp);
  fclose(fp);

  // Load RIGHT TRANSMISSION
  for (int i=0; i<NUMFILTERS; i++) {
    transmission2[i] = 0.0;
  }
  fp = fopen("configuration/transmission_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/transmission_right.bin'\n");
    return;
  }
  fread(transmission2,sizeof(transmission2),1,fp);
  fclose(fp);

  // Load GAIN RATE
  for (int i=0; i<NUMFILTERS; i++) {
    gainrate[i] = 0.0;
  }
  fp = fopen("configuration/gainrate.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/gainrate.bin'\n");
    return;
  }
  fread(gainrate,sizeof(gainrate),1,fp);
  fclose(fp);

  // Reset remaining variables
  for (int i=0; i<NUMFILTERS; i++) {
    transmissionbuffer[i] = 0.0;
  }
  for (int i=0; i<2*ORDER*NUMFILTERS; i++) {
    state1[i] = 0.0;
    state2[i] = 0.0;
  }
  for (int i=0; i<2*TICKSIZE*NUMFILTERS; i++) {
    buffer1[i] = 0.0;
    buffer2[i] = 0.0;
  }
  for (int i=0; i<NUMFILTERS; i++) {
    maxima1[i] = 0.0;
    maxima2[i] = 0.0;
  }
  for (int i=0; i<NUMFILTERS; i++) {
    age1[i] = 0;
    age2[i] = 0;
  }
  for (int i=0; i<NUMLAYERS*NUMFILTERS; i++) {
    layers1[i] = 0.0;
    layers2[i] = 0.0;
  }
  for (int i=0; i<2*NUMLAYERS*NUMFILTERS; i++) {
    layerbuffer1[i] = 0.0;
    layerbuffer2[i] = 0.0;
  }
  for (int i=0; i<(NUMLAYERS-1)*NUMFILTERS; i++) {
    differences1[i] = 0.0;
    differences2[i] = 0.0;
  }
  for (int i=0; i<NUMLAYERS*NUMFILTERS; i++) {
    target1[i] = 0.0;
    target2[i] = 0.0;
  }
  for (int i=0; i<NUMFILTERS; i++) {
    compression[i] = 0.0;
    compressionbuffer[i] = 0.0;
  }
  for (int i=0; i<NUMFILTERS; i++) {
    gain1[i] = 0.0;
    gain2[i] = 0.0;
  }

#ifdef DEBUG
  printf("\n");
  printf("SAMPLERATE: %i\n",SAMPLERATE);
  printf("NUMFILTERS: %i\n",NUMFILTERS);
  printf("ORDER: %i\n",ORDER);
  printf("TICKSAMPLES: %i\n",TICKSAMPLES);
  printf("TICKSIZE: %i\n",TICKSIZE);
  printf("MAXHOLDTICKS: %i\n",MAXHOLDTICKS);
  printf("MAXDECAY: %.3f\n",MAXDECAY);
  printf("LOG2DB: %.16f\n",LOG2DB);
  printf("NUMLAYERS: %i\n",NUMLAYERS);
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("freqs[%i] = [%.8f]\n",i,freqs[i]);
  }
  printf("\n");

  for (int i=0;i<4*NUMFILTERS;i+=4) {
    printf("coeff[%i...] = [%.8f %.8f %.8f %.8f]\n",i,coeff[i],coeff[i+1],coeff[i+2],coeff[i+3]);
  }
  printf("\n");

  for (int i=0;i<2*NUMFILTERS;i+=2) {
    printf("calibration[%i...] = [%.8f %.8f]\n",i,calibration[i],calibration[i+1]);
  }
  printf("\n");

  for (int i=0;i<2*NUMFILTERS-1;i++) {
    printf("spectralmask[%i...] = [%.8f]\n",i,spectralmask[i]);
  }
  printf("\n");

  for (int i=0;i<4*NUMFILTERS;i+=4) {
    printf("io1[%i...] = [%.8f %.8f %.8f %.8f]\n",i,io1[i],io1[i+1],io1[i+2],io1[i+3]);
  }
  printf("\n");

  for (int i=0;i<4*NUMFILTERS;i+=4) {
    printf("io2[%i...] = [%.8f %.8f %.8f %.8f]\n",i,io2[i],io2[i+1],io2[i+2],io2[i+3]);
  }
  printf("\n");

  for (int i=0;i<4*NUMFILTERS;i+=4) {
    printf("io2[%i...] = [%.8f %.8f %.8f %.8f]\n",i,io2[i],io2[i+1],io2[i+2],io2[i+3]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS*GTLEVELS;i+=GTLEVELS) {
    printf("gt1[%i...] = ");
    for (int j=0;j<GTLEVELS;j++) {
      printf("%.3f ",gt1[i+j]);
    }
    printf("\n");
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS*GTLEVELS;i+=GTLEVELS) {
    printf("gt2[%i...] = ");
    for (int j=0;j<GTLEVELS;j++) {
      printf("%.3f ",gt2[i+j]);
    }
    printf("\n");
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("expansion1[%i] = [%.8f]\n",i,expansion1[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("expansion2[%i] = [%.8f]\n",i,expansion2[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("thresholds_normal[%i] = [%.8f]\n",i,thresholds_normal[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("uncomfortable_normal[%i] = [%.8f]\n",i,uncomfortable_normal[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("maxlevel1[%i] = [%.8f]\n",i,maxlevel1[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("maxlevel2[%i] = [%.8f]\n",i,maxlevel2[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("mute1[%i] = [%.8f]\n",i,mute1[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("mute2[%i] = [%.8f]\n",i,mute2[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("transmission1[%i...] = [%.8f]\n",i,transmission1[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("transmission2[%i...] = [%.8f]\n",i,transmission2[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("gainrate[%i] = [%.8f]\n",i,gainrate[i]);
  }
  printf("\n");

#endif

  plhs[0] = mxDuplicateArray(prhs[0]); // 1. in1
  plhs[1] = mxDuplicateArray(prhs[1]); // 2. in2
  mwSize M = mxGetM (prhs[0]);
  float *in1 = (float*) mxGetData(prhs[0]);
  float *in2 = (float*) mxGetData(prhs[1]);
  float *out1 = (float*) mxGetData(plhs[0]);
  float *out2 = (float*) mxGetData(plhs[1]);

  for (int i=0; i<M; i++) {
    out1[i] = 0.0;
    out2[i] = 0.0;
  }

  for (int i=0; i<(M-TICKSAMPLES); i+=TICKSAMPLES) {
    tick(&in1[i], &in2[i], &out1[i], &out2[i]);
  }
}


