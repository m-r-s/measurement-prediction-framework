#!/bin/bash
#
# Essential Measurement Applications
#
# Main author: (2020-2021) Marc René Schädler
# E-Mail: marc.r.schaedler@uni-oldenburg.de

# Get the directory this script is stored in and its name
DIR=$(cd "$( dirname "$0" )" && pwd)
SCN=$(basename "$0")

# Set the version string
export EMA_VERSION=3.2.0

# Audio setup configuration
SOUNDDEVICE=USB
SOUNDSTREAM=0
SOUNDCHANNELS=1,2
SAMPLERATE=48000 # MUST be 48000 Hz
FRAGSIZE=960 # MUST be multiple of 48 (1ms)
PERIODS=4 #
INPUTS=("" "")
OUTPUTS=('system:playback_1' 'system:playback_2') # left right

# Define mfile directory
MADDPATH="${DIR}/mfiles/"
MSTIMULUSPATH="${DIR}/stimulus/"

# Simulated impairments by playback of a threshold simulating noise
IMPAIRMENTS=('none')
IMPAIRMENTSTRINGS=('No simulated impairment')

# Define measurement blocks <measurement>,<processing>[,individual]-<measurement-parameters>
MEASUREMENTS=()
# 1. TRAINING
MEASUREMENTS[0]='sweep,none-1000,b,train matrix,none-default,quiet,65,b,train'

# 2. SWEEPS
MEASUREMENTS[1]='sweep,none-250,l sweep,none-500,l sweep,none-1000,l sweep,none-2000,l sweep,none-4000,l sweep,none-6000,l sweep,none-250,r sweep,none-500,r sweep,none-1000,r sweep,none-2000,r sweep,none-4000,r sweep,none-6000,r'

# 3. TONE IN NOISE
MEASUREMENTS[2]='sweepinnoise,none-500,l sweepinnoise,none-1000,l sweepinnoise,none-2000,l sweepinnoise,none-4000,l sweepinnoise,none-500,r sweepinnoise,none-1000,r sweepinnoise,none-2000,r sweepinnoise,none-4000,r'

# 4. MATRIX
MEASUREMENTS[3]='matrix,none-default,quiet,0,b matrix,none-default,whitenoise,65,b matrix,openMHA-default,quiet,65,b matrix,openMHA-default,whitenoise,65,b'

MEASUREMENTSTRINGS=('Training' 'Tone detection' 'Tone detection in noise' 'Matrix sentence tests')
MEASUREMENTSEQUENCES=('unchanged' 'random' 'random' 'random')

# Say hello
echo ""
echo "      === Essential Measurement Applications ==="
echo "                  Version '${EMA_VERSION}'"
echo ""

# Define some functions
error() {
  echo "error: ${1}"
  [ -n "$PROCESSINGPID" ] && kill "$PROCESSINGPID"  &> /dev/null  &
  [ -n "$IMPAIRMENTPID" ] && kill "$IMPAIRMENTPID"  &> /dev/null &
  [ -n "$JACKPID" ] && kill "$JACKPID" &> /dev/null &
  [ -n "$LOOPPID" ] && kill "$LOOPPID" &> /dev/null &
  echo ""
  exit 1
}

finish() {
  [ -n "$PROCESSINGPID" ] && kill "$PROCESSINGPID" &> /dev/null  &
  [ -n "$IMPAIRMENTPID" ] && kill "$IMPAIRMENTPID" &> /dev/null &
  [ -n "$JACKPID" ] && kill "$JACKPID" &> /dev/null &
  [ -n "$LOOPPID" ] && kill "$LOOPPID" &> /dev/null &
  echo ""
  exit 0
}

start_measurement() {
  local TARGETFILE
  local IMPAIRMENT
  local CONDITIONCODE
  local CONDITION
  local MEASUREMENT
  local PROCESSING
  local INDIVIDUAL
  local PARAMETERS
  local IMPAIRMENTDIR
  local IMPAIRMENTPID
  local PROCESSINGDIR
  local PROCESSINGPID
  local PROCESSINGDEVICE

  TARGETFILE="$1"
  IMPAIRMENT="$2"
  CONDITIONCODE=($(echo "${3}" | tr '-' ' '))
  CONDITION=($(echo "${CONDITIONCODE[0]}" | tr ',' ' '))
  MEASUREMENT="${CONDITION[0]}"
  PROCESSING="${CONDITION[1]}"
  INDIVIDUAL="${CONDITION[2]}"
  PARAMETERS="${CONDITIONCODE[1]}"

  # Start the impairment simulation
  if [ "$IMPAIRMENT" == "none" ]; then
    echo "No threshold simulating noise"
  else
    IMPAIRMENTDIR="${DIR}/impairment/${IMPAIRMENT}/"
    [ -e "${IMPAIRMENTDIR}/thresholdsimulatingnoise.wav" ] || error "threshold simulating noise file does not exist: '${IMPAIRMENTDIR}/thresholdsimulatingnoise.wav'"
    octave-cli --quiet --eval "addpath('${MADDPATH}');playwavfile('${IMPAIRMENTDIR}/thresholdsimulatingnoise.wav', 'b', 'loop');" &>/dev/null & disown
    IMPAIRMENTPID=$!
    sleep 2
  fi
  
  # Start the processing
  if [ "$PROCESSING" == "none" ]; then
    echo "No signal processing"
    PROCESSINGPID=""
    PROCESSINGDEVICE='loop'
  else
    case "$INDIVIDUAL" in
      "id")
        PROCESSINGDIR="${DIR}/data/${ID}/processing/${PROCESSING}/"
      ;;
      "")
        PROCESSINGDIR="${DIR}/processing/${PROCESSING}/"
      ;;
      *)
        error "individual processing missing!"
      ;;
    esac
    ${DIR}/start_processing.sh "${PROCESSINGDIR}" "" "" "loop:input_1" "loop:input_2" &>> "$PROCESSINGLOG" || error "start processing failed"
    PROCESSINGPID=$(cat "${PROCESSINGDIR}/processing.pid")
    PROCESSINGDEVICE=($(cat "${PROCESSINGDIR}/processing.ports" | tr ',' '\n' | cut -d: -f1 | sort -u))
    [ "${#PROCESSINGDEVICE[@]}" -eq 1 ] || error "multiple devices requested"
    sleep 0.5
  fi
  
  # Start the measurement script
  case "$MEASUREMENT" in
    sweep)
      echo "Start sweep measurements..."
      octave-cli --quiet --eval "addpath('${MADDPATH}');addpath('${MSTIMULUSPATH}');measure_sweep('${TARGETFILE}','${PARAMETERS}','${PROCESSINGDEVICE}')" \
        2>> "$OCTAVELOG" | tee -a "$USERLOG" || error "sweep measurement failed"
    ;;
    sweepinnoise)
      echo "Start sweep in noise measurements..."
      octave-cli --quiet --eval "addpath('${MADDPATH}');addpath('${MSTIMULUSPATH}');measure_sweepinnoise('${TARGETFILE}','${PARAMETERS}','${PROCESSINGDEVICE}')" \
        2>> "$OCTAVELOG" | tee -a "$USERLOG" || error "sweep in noise measurement failed"
    ;;
    matrix)
      echo "Start matrix measurements..."
      octave-cli --quiet --eval "addpath('${MADDPATH}');addpath('${MSTIMULUSPATH}');measure_matrix('${TARGETFILE}','${PARAMETERS}','${PROCESSINGDEVICE}')" \
        2>> "$OCTAVELOG" | tee -a "$USERLOG" || error "matrix measurement failed"
    ;;
    loudness)
      echo "Start loudness measurements..."
      octave-cli --quiet --eval "addpath('${MADDPATH}');addpath('${MSTIMULUSPATH}');measure_loudness('${TARGETFILE}','${PARAMETERS}','${PROCESSINGDEVICE}')" \
        2>> "$OCTAVELOG" | tee -a "$USERLOG" || error "loudness measurement failed"
    ;;
    *)
    echo "Measurement '${MEASUREMENT}' not defined"
    ;;
  esac
  [ -n "$PROCESSINGPID" ] && ps -p "$PROCESSINGPID" &> /dev/null && kill "$PROCESSINGPID" &> /dev/null
  [ -n "$IMPAIRMENTPID" ] && ps -p "$IMPAIRMENTPID" &> /dev/null && kill "$IMPAIRMENTPID" &> /dev/null
  sleep 0.1
}

ui_get_user_data() {
  local IDS
  local IDN
  ID=''
  while [ -z "$ID" ] || [[ "$ID" == *' '* ]]; do
    echo ""
    echo "Available IDs:"
    IDS=($(ls -1 data 2> /dev/null))
    echo "${IDS[@]}" | tr ' ' '\n' | awk '{if (length($0) > 0) {print " "NR") "$0}}'
    echo ""
    IDN=''
    while ! [[ "$IDN" =~ ^[0-9]+$ ]]; do
      echo -n "Select ID (number, 0 creates new ID): "
      read IDN
    done
    if [ "$IDN" == 0 ]; then
      ID=''
      while [ -z "$ID" ]; do
        echo -n "New ID: "
        read ID
      done
    else
      ID="${IDS[$[${IDN}-1]]}"
    fi
  done
  echo ""
}

ui_delete_measurements() {
  local DELETE
  local RESULTSFILE
  local DATA
  local CONDITIONS
  DELETE=''
  while ! [ "$DELETE" == 0 ]; do
    DATA=$(cd "$WORKDIR" && grep -H -R threshold *.m 2> /dev/null | sed -E -e 's/.m:threshold[ ]*=[ ]*\[/ /g' -e 's/[ ]*\];[ ]*$//g' | sort -n )
    CONDITIONS=($(echo -e "${DATA}" | cut -d' ' -f1))
    echo ""
    echo -e "$DATA" | awk 'BEGIN {print "# MEASUREMENT THRESHOLD\n"} {if (length($0) > 0) {print NR ") "$1" "$2}}' | column -t
    echo ""
    DELETE=''
    while ! [[ "$DELETE" =~ ^[0-9]+$ ]]; do
      echo -n "Select to delete (number, 0 leave this menu): "
      read DELETE
    done
    if [ "${DELETE}" -gt 0 ]; then
      RESULTSFILE="${WORKDIR}/${CONDITIONS[$[${DELETE}-1]]}.m"
      if [ -e "$RESULTSFILE" ]; then
        echo -n "Delete condition '${CONDITIONS[$[${DELETE}-1]]}'... "
        mv "$RESULTSFILE" "${RESULTSFILE}.$(date --iso-8601=seconds).del" &> /dev/null || error 'delete measurement'
      echo "OK"
      fi
    fi
    echo ""
  done
}

ui_plot_measurements() {
  local PLOT
  local RESULTSFILE
  local DATA
  local CONDITIONS
  PLOT=''
  while ! [ "$PLOT" == 0 ]; do
    DATA=$(cd "$WORKDIR" && grep -H -R threshold *.m | sed -E -e 's/.m:threshold[ ]*=[ ]*\[/ /g' -e 's/[ ]*\];[ ]*$//g' | sort -n ) &> /dev/null
    CONDITIONS=($(echo -e "${DATA}" | cut -d' ' -f1))
    echo ""
    echo -e "${DATA}" | awk 'BEGIN {print "# MEASUREMENT THRESHOLD\n"} {if (length($0) > 0) {print NR ") "$1" "$2}}' | column -t
    echo ""
    PLOT=''
    while ! [[ "$PLOT" =~ ^[0-9]+$ ]]; do
      echo -n "Select to plot (number, 0 leave this menu): "
      read PLOT
    done
    if [ "$PLOT" -gt 0 ]; then
      echo "Plot condition '${CONDITIONS[$[${PLOT}-1]]}'"
      RESULTSFILE="${WORKDIR}/${CONDITIONS[$[${PLOT}-1]]}.m"
      octave --quiet --eval "addpath('${MADDPATH}');plot_run('${RESULTSFILE}');" &>> "$OCTAVELOG" 
      echo ""
    fi
    echo ""
  done
}

change_id() {
  ui_get_user_data || error 'load user data'
  WORKDIR="${PWD}/data/${ID}"
  mkdir -p "$WORKDIR" || error 'create workdir'
}

calibration_stimuli() {
  local STIMULIDIR
  local PLAY
  local FILES
  local PLAYFILE

  STIMULIDIR="${DIR}/platt-tools/calibrationstimuli"
  if [ ! -e "$STIMULIDIR" ]; then
    echo "Generating calibration stimuli..."
    (cd "${DIR}/platt-tools/" && ./generate_calibrationstimuli.m &>> "$OCTAVELOG")
  fi
  DATA=$(cd "$STIMULIDIR" && ls -1 *.wav | sort -n)
  FILES=($(echo "$DATA"))
  PLAY=''
  while ! [ "$PLAY" == 0 ]; do
    echo ""
    echo -e "${DATA}" | tr '_' ' ' | cut -d' ' -f1,2 | awk 'BEGIN {print "# FREQUENCY LEVEL\n"} {if (length($0) > 0) {print NR ") "$1" "$2}}' | column -t
    echo ""
    PLAY=''
    while ! [[ "${PLAY}" =~ ^([lr] )?[0-9]+$ ]]; do
      echo -n "Select to play (l|r number, 0 leave this menu): "
      read PLAY
    done
    if [ -n "${PLAY:2}" ] && [ "${PLAY:2}" -gt 0 ]; then
      PLAYFILE="${STIMULIDIR}/${FILES[$[${PLAY:2}-1]]}"
      echo "Play file '${PLAYFILE}' on channel '${PLAY:0:1}'"

      octave-cli --quiet --eval "addpath('${MADDPATH}');playwavfile('${PLAYFILE}','${PLAY:0:1}','loop')" \
        &>> "$OCTAVELOG"
    fi
    echo ""
  done
}

# Enter script directory
cd ${DIR} || error "enter script directory"

# Make some folder
[ -e 'log' ] || mkdir log
[ -e 'data' ] || mkdir data

# Define destinations for logging
JACKLOG="${PWD}/log/jack.log"
OCTAVELOG="${PWD}/log/octave.log"
LOOPLOG="${PWD}/log/loop.log"
PROCESSINGLOG="${PWD}/log/processing.log"
USERLOG="${PWD}/log/user.log"

# Initial audio setup
killall -9 loop &> /dev/null &
killall -9 mha &> /dev/null &
killall -9 platt &> /dev/null &
killall -9 jackd &> /dev/null &
sleep 1
[ -z "$(pidof loop)" ] || error 'zombie loop'
[ -z "$(pidof mha)" ] || error 'zombie mha'
[ -z "$(pidof platt)" ] || error 'zombie platt'
[ -z "$(pidof jackd)" ] || error 'zombie jackd'

# Start JACK
echo -n "Start JACK... "
pasuspender -- jackd --realtime -d alsa -d "hw:${SOUNDDEVICE},${SOUNDSTREAM}" \
  -p "$FRAGSIZE" -n "$PERIODS" -r "$SAMPLERATE" &>> "$JACKLOG" &
sleep 0.5
JACKPID=$(pidof jackd)
[ -n "$JACKPID" ] || error 'start JACK'
echo "OK"

# Start calibration filter loop
echo -n "Start loop... "
(cd ${DIR}/loop-bin && ./loop) &>> "$LOOPLOG" &
sleep 0.5
LOOPPID=$(pidof loop)
[ -n "$LOOPPID" ] || error 'start loop'
jack_connect "loop:output_1" "${OUTPUTS[0]}" &>> "$LOOPLOG" || error "connect loop"
jack_connect "loop:output_2" "${OUTPUTS[1]}" &>> "$LOOPLOG" || error "connect loop"
echo "OK"

# ID init
change_id || error 'id setup'

# Start menu loop
TASK="menu"
while true; do
  CONFIG="EMA:${EMA_VERSION},ID:${ID},SOUNDDEVICE:${SOUNDDEVICE},SOUNDSTREAM:${SOUNDSTREAM},SOUNDCHANNELS:${SOUNDCHANNELS}"
  case "${TASK}" in
    [0-9][0-9])
      I=$[${TASK:0:1}-1]
      J=$[${TASK:1:1}-1]
      BLOCK="BLOCK${TASK}"
      IMPAIRMENT="${IMPAIRMENTS[$I]}"
      case "${MEASUREMENTSEQUENCES[$J]}" in
        ordered)
          MEASUREMENT=($(echo "${MEASUREMENTS[$J]}" | tr " " "\n" | sort | tr "\n" " "))
        ;;
        random)
          MEASUREMENT=($(echo "${MEASUREMENTS[$J]}" | tr " " "\n" | sort -R | tr "\n" " "))
        ;;
        *)
          MEASUREMENT=(${MEASUREMENTS[$J]})
        ;;
      esac
      for ((K=0;$K<${#MEASUREMENT[@]};K++)); do
        TARGETFILE="${WORKDIR}/${BLOCK}-${IMPAIRMENT}-${MEASUREMENT[$K]}.m"
        if [ -e "${TARGETFILE}" ]; then
          echo "Measurement '${MEASUREMENT[$K]}' with simulated impairment '${IMPAIRMENT}' already completed... skip"
        else
          echo -e "\nStart measurement '${MEASUREMENT[$K]}' with simulated impairment '${IMPAIRMENT}'"
          CONTINUE='!'
          while ! [[ "${CONTINUE}" =~ ^(y|Y|n|N|)$ ]]; do
            echo -n "Continue (Y/n): "
            read CONTINUE
          done
          [[ "${CONTINUE}" =~ ^(n|N)$ ]] && break
          start_measurement "${TARGETFILE}" "${IMPAIRMENT}" "${MEASUREMENT[$K]}" || error "measurement failed"
        fi
      done
      TASK=menu
    ;;
    1)
      change_id || error 'change id'
      TASK=menu
    ;;
    2)
      ui_plot_measurements || error 'plot measurements'
      TASK=menu
    ;;
    3)
      ui_delete_measurements || error 'delete measurements'
      TASK=menu
    ;;
    8)
      calibration_stimuli || error 'change id'
      TASK=menu
    ;;
    9)
      echo ""
      echo "  Essential Measurement Applications Version (${EMA_VERSION})"
      echo "  Author (2020) Marc René Schädler"
      echo "  E-Mail: marc.rene.schaedler@uni-oldenburg.de"
      echo ""
      echo -n "Press enter to return to menu..."
      read
      TASK=menu
    ;;
    0)
      echo ""
      finish
    ;;
    menu)
      echo ""
      echo "       +------------------------------------------------------------"
      echo "-------|  VERSION ${EMA_VERSION}"
      echo "  EMA  |------------------------------"
      echo "-------|  ID ${ID}"
      echo "       +---------------"
      echo ""
      echo "    1)   Change ID (${ID})"
      echo "    2)   Plot measurements"
      echo "    3)   Delete measurements"
      echo "    8)   Calibration stimuli"
      echo "    9)   Help"
      echo "    0)   Quit"
      echo ""
      for ((I=0;$I<${#IMPAIRMENTS[@]};I++)); do
        IMPAIRMENT=${IMPAIRMENTS[$I]}
        echo "  ====   $[$I+1]. ${IMPAIRMENTSTRINGS[$I]} (${IMPAIRMENTS[$I]})"
        echo ""
        for ((J=0;$J<${#MEASUREMENTS[@]};J++)); do
          MEASUREMENT=(${MEASUREMENTS[$J]})
          STATUS=$(find "$WORKDIR" -type f -iname "BLOCK$[$I+1]$[$J+1]-*.m" 2> /dev/null | \
    wc -l)"/${#MEASUREMENT[@]}"
          echo "  $[$I+1]$[$J+1])   ${STATUS} ${MEASUREMENTSTRINGS[$J]}"
        done
        echo ""
      done
      TASK=''
      while [ -z "${TASK}" ]; do
        echo -n "Selection: "
        read TASK
      done
    ;;
    *)
      echo "Option '${TASK}' not found"
      TASK=menu
    ;;
  esac
done



