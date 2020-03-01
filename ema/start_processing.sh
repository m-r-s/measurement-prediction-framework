#!/bin/bash
#
# Script to start 2i2o real-time signal processing with MHA or PLATT
#
# Copyright (2020) Marc René Schädler
# E-Mail: marc.r.schaedler@uni-oldenburg.de

# Get the directory this script is stored in and its name
DIR=$(cd "$( dirname "$0" )" && pwd)
SCN=$(basename "$0")

if [ $# -lt 4 ]; then
  echo "usage: ${SCN} CONFIGDIR IN1 IN2 OUT1 OUT2"
fi

CONFIGDIR="$1"
IN1="$2"
IN2="$3"
OUT1="$4"
OUT2="$5"

if [ ! -e "$CONFIGDIR" ]; then
  echo "Configuration directory '$CONFIGDIR' does not exist"
  exit 1
fi

echo "Enter configuration directory: '$CONFIGDIR'"
cd "$CONFIGDIR" || exit 1

# look for openMHA config for playback with jack
if [ -e "openMHA.cfg" ] && [ -e "jack-playback.cfg" ]; then
  echo "Start MHA with configuration from 'openMHA.cfg' and 'jack-playback.cfg'"
  mha "?read:openMHA.cfg" "?read:jack-playback.cfg" "cmd=start" &
  sleep 0.5
  PID=$(pidof mha)
  [ -n "$PID" ] || exit 1
  echo "$PID" > processing.pid
  PROC_IN1="MHA:in_1"
  PROC_IN2="MHA:in_2"
  PROC_OUT1="MHA:out_1"
  PROC_OUT2="MHA:out_2"
fi

# look for platt config
if [ -e "platt.cfg" ]; then
  echo "Start PLATT with configuration files from 'configuration/'"
  platt &
  sleep 0.5
  PID=$(pidof platt)
  [ -n "$PID" ] || exit 1
  echo "$PID" > processing.pid
  PROC_IN1="platt:input_1"
  PROC_IN2="platt:input_2"
  PROC_OUT1="platt:output_1"
  PROC_OUT2="platt:output_2"
fi

echo "${PROC_IN1},${PROC_IN2}" > processing.ports

echo "Connect requested ports"
if [ -n "$IN1" ]; then
  jack_connect "$IN1" "$PROC_IN1" || exit 1
fi
if [ -n "$IN2" ]; then
  jack_connect "$IN2" "$PROC_IN2" || exit 1
fi
if [ -n "$OUT1" ]; then
  jack_connect "$PROC_OUT1" "$OUT1" || exit 1
fi
if [ -n "$OUT2" ]; then
  jack_connect "$PROC_OUT2" "$OUT2" || exit 1
fi

exit 0
