#!/bin/bash

CFLAGS="-Wall -Ofast"

error() {
  echo "$1"
  exit 1
}

# Compile all C code

# IIR implementation for tuning gammatone filter coefficients
(cd platt/tools && mkoctfile --mex iir4.c ${CFLAGS}) || error "iir4"

# Loop for calibration and compensation filters
(cd loop/src/jack && gcc ${CFLAGS} loop.c -o loop -ljack) || error "loop jack plugin"

# Update compensation filters
(cd loop/tools && ./update_configuration.m) || error "loop configuration"
