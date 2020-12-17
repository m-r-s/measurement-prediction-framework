#!/bin/bash

CFLAGS="-Wall -Ofast"

error() {
  echo "$1"
  exit 1
}

# Compile all C code

# IIR implementation for tuning gammatone filter coefficients
(cd platt/tools && mkoctfile --mex iir4.c ${CFLAGS}) || error "iir4"

# PLATT dynamic compressor mex files for Matlab/Octave
(cd platt/src/octave && find -iname '*_wrapper.c' | xargs -n1 -i_FILE_ mkoctfile --mex _FILE_ ${CFLAGS}) || error "mex wrapper for platt code blocks"
(cd platt/src/octave && mkoctfile --mex platt.c ${CFLAGS}) || error "mex wrapper for platt"

# PLATT dynamic compressor as JACK plugin
(cd platt/src/jack && gcc ${CFLAGS} platt.c -o platt -lm -ljack) || error "platt jack plugin"

# ABHANG feedback cancellation as JACK plugin
(cd abhang/src/jack && gcc ${CFLAGS} abhang.c -o abhang -lm -ljack) || error "abhang"
(cd abhang/tools && gcc ${CFLAGS} whitenoise.c -o whitenoise -lm -ljack) || error "whitenoise"

# Loop for calibration and compensation filters
(cd loop/src/jack && gcc ${CFLAGS} loop.c -o loop -ljack) || error "loop jack plugin"

# Update compensation filters
(cd loop/tools && ./update_configuration.m) || error "loop configuration"
