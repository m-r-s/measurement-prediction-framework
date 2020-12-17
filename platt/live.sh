#!/bin/bash

# Simple sound configuration
SOUNDDEVICE=USB
SOUNDSTREAM=0
SOUNDCHANNELS=1,2
SAMPLERATE=48000
FRAGSIZE=96
NPERIODS=3

killall whitenoise -9 &> /dev/null
killall abhang -9 &> /dev/null
killall platt -9 &> /dev/null
killall jackd -9 &> /dev/null
sleep 3

taskset -c 1 jackd --realtime -d alsa -d hw:$SOUNDDEVICE,$SOUNDSTREAM -p $FRAGSIZE -r $SAMPLERATE -n $NPERIODS -s 2>&1 &
sleep 1

# Configure ABHANG
echo "Start white noise"
../abhang/tools/whitenoise &
sleep 0.1
jack_connect whitenoise:output_1 system:playback_2
jack_connect whitenoise:output_2 system:playback_1
echo "Record feedback"
jack_rec -f "/tmp/feedback.wav" -d 10 -b 32 whitenoise:output_1 whitenoise:output_2 system:capture_1 system:capture_2
killall whitenoise
(cd ../abhang/tools && ./update_configuration.m)

# Start ABHANG and PLATT
(cd ../abhang/src/jack && taskset -c 2 ./abhang) 2>&1 &
(cd src/jack && taskset -c 3 ./platt) 2>&1 &
sleep 1

# Connections
echo "Connect everything"
jack_connect system:capture_1 abhang:input_1
jack_connect system:capture_2 abhang:input_2
jack_connect platt:output_1 abhang:input_3
jack_connect platt:output_2 abhang:input_4
jack_connect abhang:output_1 platt:input_1
jack_connect abhang:output_2 platt:input_2
jack_connect platt:output_1 system:playback_2
jack_connect platt:output_2 system:playback_1
