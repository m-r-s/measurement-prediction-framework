#!/bin/bash

# Get the directory this script is stored in and its name
DIR=$(cd "$( dirname "$0" )" && pwd)
SCN=$(basename "$0")

if [ $# -lt 7 ]; then
  echo "Usage: $0 PROJECTDIR MEASUREMENTSTRING SIMRANGE SIMMODE FEATURES INDIVIDUALIZATION INDIVIDUAL EAR ..."
  echo ""
  exit 1
fi

error() {
  echo "error: $1"
  exit 1
}

# Get arguments
PROJECTDIR="$1"
MEASUREMENTSTRING="$2"
SIMRANGE="$3"
SIMMODE="$4"
FEATURES="$5"
INDIVIDUALIZATION="$6"
INDIVIDUAL="$7"
EAR="$8"

case "$SIMMODE" in
  coarse)
    TRAININGSAMPELSPERMODEL=12
    RECOGNITIONDECISIONS=100
    # [STATES] [SILENCE_STATES] [MIXTURES] [ITERATIONS] [UPDATES] [PRUNINGS] [BINARY]
    TRAININGOPTIONS="4 4 1 4 mvwt 0 1"
    RECOGNITIONOPTIONS="0 50 1"
    FEATURESMODE="${FEATURES}-reduced"
  ;;
  medium)
    TRAININGSAMPELSPERMODEL=48
    RECOGNITIONDECISIONS=300
    # [STATES] [SILENCE_STATES] [MIXTURES] [ITERATIONS] [UPDATES] [PRUNINGS] [BINARY]
    TRAININGOPTIONS="6 4 1 4 mvwt 0 1"
    RECOGNITIONOPTIONS="0 100 1"
    FEATURESMODE="${FEATURES}-reduced"
  ;;
  precise)
    TRAININGSAMPELSPERMODEL=96
    RECOGNITIONDECISIONS=600
    # [STATES] [SILENCE_STATES] [MIXTURES] [ITERATIONS] [UPDATES] [PRUNINGS] [BINARY]
    TRAININGOPTIONS="8 6 1 8 mvwt 0 1"
    MATCHEDSNRS=0
    RECOGNITIONOPTIONS="0 200 1"
    FEATURESMODE="${FEATURES}-full"
  ;;
esac

if [ -e "${PROJECTDIR}" ]; then
  echo "project directory already exists '${PROJECTDIR}'"
  exit 0
fi

# Decode condition code
CONDITIONCODE=($(echo "$MEASUREMENTSTRING" | tr '-' ' '))
CONDITION=($(echo "${CONDITIONCODE[0]}" | tr ',' ' '))
PARAMETERS=($(echo "${CONDITIONCODE[1]}" | tr ',' ' '))
MEASUREMENT="${CONDITION[0]}"
PROCESSING="${CONDITION[1]}"

if [ "${CONDITION[2]}" == "id" ]; then
  PROCESSINGDIR="${DIR}/data/${INDIVIDUAL}/processing/${PROCESSING}/"
elif [ "${CONDITION[2]}" == "" ]; then
  PROCESSINGDIR="${DIR}/processing/${PROCESSING}/"
else
  error "unknown processing parameter"
fi
FEATURESDIR="${DIR}/features/${FEATURESMODE}/"

# Set up experiment
case "$MEASUREMENT" in
  sweep)
    QSIM_THRESHOLD=0.875
    fade "$PROJECTDIR" corpus-stimulus "$[${TRAININGSAMPELSPERMODEL}*1]" "$[${RECOGNITIONDECISIONS}/2]" || error "creating project"
    FREQUENCY=${PARAMETERS[0]}
    cp -L "${DIR}/stimulus/"* "${PROJECTDIR}/config/corpus/matlab" || error "copying stimulus generation files"
    cp -L "${DIR}/stimulus/control_"* "${PROJECTDIR}/config/figures/matlab" || error "copying stimulus control files"
    echo "function generate(target_dir, samples, seed, verbose)
          mkdir(target_dir);
          classes = {0 1};
          % Sweep in noise detection
          funname = 'gensweep';
          values = ${SIMRANGE};
          generate_conditions(target_dir, funname, classes, ...
            num2cell(values), samples, {'${FREQUENCY}'}, seed, verbose);
          " > "${PROJECTDIR}/config/corpus/matlab/generate.m"
  ;;
  sweepinnoise)
    QSIM_THRESHOLD=0.875
    fade "$PROJECTDIR" corpus-stimulus "$[${TRAININGSAMPELSPERMODEL}*1]" "$[${RECOGNITIONDECISIONS}/2]" || error "creating project"
    FREQUENCY=${PARAMETERS[0]}
    cp -L "${DIR}/stimulus/"* "${PROJECTDIR}/config/corpus/matlab" || error "copying stimulus generation files"
    cp -L "${DIR}/stimulus/control_"* "${PROJECTDIR}/config/figures/matlab" || error "copying stimulus control files"
    echo "function generate(target_dir, samples, seed, verbose)
          mkdir(target_dir);
          classes = {0 1};
          % Sweep in noise detection
          funname = 'gensweepinnoise';
          values = ${SIMRANGE};
          generate_conditions(target_dir, funname, classes, ...
            num2cell(values), samples, {'${FREQUENCY}'}, seed, verbose);
          " > "${PROJECTDIR}/config/corpus/matlab/generate.m"
  ;;
  matrix)
    QSIM_THRESHOLD=0.5
    TALKER="${PARAMETERS[0]}"
    NOISEMASKER="${PARAMETERS[1]}"
    NOISELEVEL="${PARAMETERS[2]}"
    fade "$PROJECTDIR" corpus-matrix "$[${TRAININGSAMPELSPERMODEL}*10]" "$[${RECOGNITIONDECISIONS}/5]" || error "creating project"
    cp -L "${DIR}/matrix/speech/${TALKER}/"*".wav" "${PROJECTDIR}/source/speech/" || error "copying speech files"
    cp -L "${DIR}/matrix/maskers/${NOISEMASKER}.wav" "${PROJECTDIR}/source/noise/" || error "copying masker file"
    (cd "${PROJECTDIR}/source" && find -iname '*.wav') > "${PROJECTDIR}/config/sourcelist.txt"
    # Adjust level and resample to 44100Hz
    echo "Adjust levels and resample"
    octave-cli --quiet --eval "
      filelist = strsplit(fileread('${PROJECTDIR}/config/sourcelist.txt'),'\n');
      numfiles = length(filelist);
      for i=1:numfiles
        if ~isempty(filelist{i})
          filename = ['${PROJECTDIR}/source/' filelist{i}];
          [signal, fs] = audioread(filename);
          signal = signal.*10.^((${NOISELEVEL}-65)./20);
          if fs ~= 44100
            signal = resample(signal, 44100, fs);
          end
          audiowrite(filename, signal, 44100, 'BitsPerSample', 32);
          printf('.');
        end
      end
      printf('\nfinished\n');" || error "adjusting levels"
    sed -i "s/^SNRS=.*/SNRS=${SIMRANGE}/g" "${PROJECTDIR}/config/corpus/generate.cfg"
  ;;
esac

# Parallel compuations
fade "$PROJECTDIR" parallel

# Generate corpus
fade "$PROJECTDIR" corpus-generate || error "generating corpus"

# Perform signal processing
if [ ! "$PROCESSING" == "none" ]; then
  echo "Apply signal processing"
  [ -e "$PROCESSINGDIR" ] || error "processingdir not found"
  fade "$PROJECTDIR" processing "$PROCESSINGDIR" || error "processing"
fi

# Extract features
fade "$PROJECTDIR" features "$FEATURESDIR" "$INDIVIDUALIZATION" "$INDIVIDUAL" "$EAR" || error "extracting features"

# Format corpus (determine training/testing combinations)
if [ "$SIMMODE" == "coarse" ] || [ "$SIMMODE" == "medium" ] ; then
  case "$MEASUREMENT" in
    sweep)
      CONDITION_CODE='o o o'
    ;;
    sweepinnoise)
      CONDITION_CODE='o o o'
    ;;
    matrix)
      CONDITION_CODE='o o'
    ;;
  esac
  sed -i "s/^CONDITION_CODE=.*$/CONDITION_CODE='${CONDITION_CODE}'/g" "${PROJECTDIR}/config/corpus/format.cfg"
fi
fade "$PROJECTDIR" corpus-format || error "formatting corpus"

# Training
fade "$PROJECTDIR" training $TRAININGOPTIONS || error "training"

# Recognition
fade "$PROJECTDIR" recognition $RECOGNITIONOPTIONS || error "recognition"

# Evaluation
fade "$PROJECTDIR" evaluation || error "evaluating results"

case "$SIMMODE" in
  coarse|medium)
  # Evaluate quick simulation to find point of interest

  POI=$(cat "${PROJECTDIR}/evaluation/summary" | \
        sed -E 's/.*_([^_]*)$/\1/g' | sed -E 's/^(snr)?\+?//g' | \
        cut -d' ' -f1,2,3 | sort -n | \
        awk -F' ' -vt="${QSIM_THRESHOLD}" '{x1=$1;y1=$3/$2;if (y1>t) {if (NR>1) {printf "%.0f",x2+(x2-x1)/(y2-y1)*(t-y2)} exit} x2=x1;y2=y1}')

  if [ -z "${POI}" ]; then
    echo -e "\nERROR: POI not found\n"
    exit 1
  fi
  echo -e "\nPOI found: ${POI}\n"
  echo "${POI}" > "${PROJECTDIR}/poi"
  ;;
  precise)
    fade "$PROJECTDIR" figures
  ;;
esac

