/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

// Gammatone center frequencies in Hz
float freqs[NUMFILTERS] = {0.0};
// Gammatone coefficients: [b0r b0i a1r a1i] * NUMFILTERS
float coeff[4*NUMFILTERS] = {0.0};
// Calibration: [in out] * NUMFILTERS
float calibration[2*NUMFILTERS] = {0.0};
// Spectral masking: NUMFILTERS*2-1
float spectralmask[NUMFILTERS*2-1] = {0.0};
float spectralbuffer[NUMFILTERS] = {0.0};
// IO [in_low in_high out_low out_high] * NUMFILTERS
float io1[4*NUMFILTERS] = {0.0};
float io2[4*NUMFILTERS] = {0.0};
// Gain table data
float gt1[GTLEVELS*NUMFILTERS] = {0.0};
float gt2[GTLEVELS*NUMFILTERS] = {0.0};
// Expansion
float expansion1[NUMFILTERS] = {0.0};
float expansion2[NUMFILTERS] = {0.0};
// Normal hearing thresholds
float thresholds_normal[NUMFILTERS] = {0.0};
// Normal hearing uncomfortable level
float uncomfortable_normal[NUMFILTERS] = {0.0};
// Max level
float maxlevel1[NUMFILTERS] = {0.0};
float maxlevel2[NUMFILTERS] = {0.0};
// Mute channels
float mute1[NUMFILTERS] = {0.0};
float mute2[NUMFILTERS] = {0.0};
// Transmission loss
float transmission1[NUMFILTERS] = {0.0};
float transmission2[NUMFILTERS] = {0.0};
float transmissionbuffer[NUMFILTERS] = {0.0};
// Gain rate
float gainrate[NUMFILTERS] = {0.0};
// Filter state: [O1r O1i, O2r O2i, O3r O3i, O4r O4i] * NUMFILTERS
float state1[2*ORDER*NUMFILTERS] = {0.0};
float state2[2*ORDER*NUMFILTERS] = {0.0};
// Buffer for gammatone filters [real imag] * TICKSIZE * NUMFILTERS
float buffer1[2*TICKSIZE*NUMFILTERS] = {0.0};
float buffer2[2*TICKSIZE*NUMFILTERS] = {0.0};
// Maxima
float maxima1[NUMFILTERS] = {0.0};
float maxima2[NUMFILTERS] = {0.0};
// Age
int age1[NUMFILTERS] = {0};
int age2[NUMFILTERS] = {0};
// Layers
float layers1[NUMLAYERS*NUMFILTERS] = {0.0};
float layers2[NUMLAYERS*NUMFILTERS] = {0.0};
// Layer buffer [old new] * NUMLAYERS * NUMFILTERS
float layerbuffer1[2*NUMLAYERS*NUMFILTERS] = {0.0};
float layerbuffer2[2*NUMLAYERS*NUMFILTERS] = {0.0};
// Differences
float differences1[(NUMLAYERS-1)*NUMFILTERS] = {0.0};
float differences2[(NUMLAYERS-1)*NUMFILTERS] = {0.0};
// Target
float target1[NUMLAYERS*NUMFILTERS] = {0.0};
float target2[NUMLAYERS*NUMFILTERS] = {0.0};
// Compression
float compression[NUMFILTERS] = {0.0};
float compressionbuffer[NUMFILTERS] = {0.0};
// Gains
float gain1[NUMFILTERS] = {0.0};
float gain2[NUMFILTERS] = {0.0};
