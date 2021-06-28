#!/bin/bash

# Get the directory this script is stored in and its name
DIR=$(cd "$( dirname "$0" )" && pwd)
SCN=$(basename "$0")

if [ $# -lt 7 ]; then
  echo "Usage: $0 PROJECTDIR MEASUREMENTSTRING SIMRANGE SIMMODE FEATURES INDIVIDUAL IMPAIRMENT"
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
INDIVIDUAL="$6"
IMPAIRMENT="$7"

case "$SIMMODE" in
  coarse)
    TRAININGSAMPELSPERMODEL=24
    RECOGNITIONDECISIONS=100
    # [STATES] [SILENCE_STATES] [MIXTURES] [ITERATIONS] [UPDATES] [PRUNINGS] [BINARY]
    TRAININGOPTIONS="4 4 1 4 mvwt 0 1"
    RECOGNITIONOPTIONS="0 50 1"
    FEATURESMODE="${FEATURES}-reduced"
  ;;
  medium)
    TRAININGSAMPELSPERMODEL=48
    RECOGNITIONDECISIONS=200
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
THRESHOLDNOISE="${DIR}/impairment/${IMPAIRMENT}/thresholdsimulatingnoise.wav"

if [ "${CONDITION[2]}" == "id" ]; then
  PROCESSINGDIR="${DIR}/data/${INDIVIDUAL}/processing/${PROCESSING}/"
elif [ "${CONDITION[2]}" == "" ]; then
  PROCESSINGDIR="${DIR}/processing/${PROCESSING}/"
else
  error "unknown processing parameter"
fi
FEATURESDIR="${DIR}/features/${FEATURESMODE}/"

# Temporary project dir in ramdisk
WORKDIR=$(mktemp -d -p /dev/shm/) || error "folder in ramdisk"
PROJECT="${WORKDIR}/simulation"

# Set up experiment
case "$MEASUREMENT" in
  sweep)
    QSIM_THRESHOLD=0.875
    fade "${PROJECT}" corpus-stimulus "$[${TRAININGSAMPELSPERMODEL}*1]" "$[${RECOGNITIONDECISIONS}/2]" || error "creating project"
    FREQUENCY=${PARAMETERS[0]}
    EAR=${PARAMETERS[1]}
    cp -L "${DIR}/stimulus/"* "${PROJECT}/config/corpus/matlab" || error "copying stimulus generation files"
    cp -L "${DIR}/stimulus/control_"* "${PROJECT}/config/figures/matlab" || error "copying stimulus control files"
    echo "function generate(target_dir, samples, seed, verbose)
          mkdir(target_dir);
          classes = {0 1};
          % Sweep in noise detection
          funname = 'gensweep';
          values = ${SIMRANGE};
          generate_conditions(target_dir, funname, classes, ...
            num2cell(values), samples, {'${FREQUENCY},${EAR}'}, seed, verbose);
          " > "${PROJECT}/config/corpus/matlab/generate.m"
  ;;
  sweepinnoise)
    QSIM_THRESHOLD=0.875
    fade "${PROJECT}" corpus-stimulus "$[${TRAININGSAMPELSPERMODEL}*1]" "$[${RECOGNITIONDECISIONS}/2]" || error "creating project"
    FREQUENCY=${PARAMETERS[0]}
    EAR=${PARAMETERS[1]}
    cp -L "${DIR}/stimulus/"* "${PROJECT}/config/corpus/matlab" || error "copying stimulus generation files"
    cp -L "${DIR}/stimulus/control_"* "${PROJECT}/config/figures/matlab" || error "copying stimulus control files"
    echo "function generate(target_dir, samples, seed, verbose)
          mkdir(target_dir);
          classes = {0 1};
          % Sweep in noise detection
          funname = 'gensweepinnoise';
          values = ${SIMRANGE};
          generate_conditions(target_dir, funname, classes, ...
            num2cell(values), samples, {'${FREQUENCY},${EAR}'}, seed, verbose);
          " > "${PROJECT}/config/corpus/matlab/generate.m"
  ;;
  matrix)
    QSIM_THRESHOLD=0.5
    TALKER="${PARAMETERS[0]}"
    NOISEMASKER="${PARAMETERS[1]}"
    NOISELEVEL="${PARAMETERS[2]}"
    EAR="${PARAMETERS[3]}"
    fade "${PROJECT}" corpus-matrix "$[${TRAININGSAMPELSPERMODEL}*10]" "$[${RECOGNITIONDECISIONS}/5]" "${SIMRANGE}" || error "creating project"
    cp -L "${DIR}/matrix/speech/${TALKER}/"*".wav" "${PROJECT}/source/speech/" || error "copying speech files"
    cp -L "${DIR}/matrix/maskers/${NOISEMASKER}.wav" "${PROJECT}/source/noise/" || error "copying masker file"
    (cd "${PROJECT}/source" && find -iname '*.wav') > "${PROJECT}/config/sourcelist.txt"
    # Adjust level and resample to 48kHz
    echo "Adjust levels, resample, and select channels"
    octave-cli --quiet --eval "ear = '${EAR}';
      filelist = strsplit(fileread('${PROJECT}/config/sourcelist.txt'),'\n');
      numfiles = length(filelist);
      for i=1:numfiles
        if ~isempty(filelist{i})
          filename = ['${PROJECT}/source/' filelist{i}];
          [signal, fs] = audioread(filename);
          signal = signal.*10.^((${NOISELEVEL}-65)./20);
          if fs ~= 48000
            signal = resample(signal, 48000, fs);
          end
          switch ear
            case 'l'
              signal(:,2) = 0;
            case 'r'
              signal(:,1) = 0;
            case 'b'

            otherwise
              error('Unknown ear definition (l/r/b)');
          end
          audiowrite(filename, signal, 48000, 'BitsPerSample', 32);
          printf('.');
        end
      end
      printf('\nfinished\n');" || error "adjusting levels"
  ;;
esac

# Parallel compuations
fade "${PROJECT}" parallel

# Generate corpus
fade "${PROJECT}" corpus-generate || error "generating corpus"

# Remove source files
[ -e "${PROJECT}/source" ] && rm -r "${PROJECT}/source"

# Perform signal processing
if [ ! "$PROCESSING" == "none" ]; then
  echo "Apply signal processing"
  [ -e "${PROCESSINGDIR}" ] || error "processingdir not found"
  fade "${PROJECT}" processing "${PROCESSINGDIR}" || error "processing"
  # And remove corpus files
  [ -e "${PROJECT}/corpus" ] && rm -r "${PROJECT}/corpus"
fi

# Apply threshold simulating noise
if [ ! "${IMPAIRMENT}" == "none" ]; then
  echo "Apply threshold simulating noise"
  if [ -e "${PROJECT}/processing" ]; then
      (cd "${PROJECT}/processing" && find "$PWD" -iname '*.wav') > "${PROJECT}/config/impairmentlist.txt" || error "finding processed files"
  elif [ -e "${PROJECT}/corpus" ]; then
      (cd "${PROJECT}/corpus" && find "$PWD" -iname '*.wav') > "${PROJECT}/config/impairmentlist.txt" || error "finding corpus files"
  else
      error "finding files for applying threshold simulating noise"
  fi
  octave-cli --quiet --eval "
    filelist = strsplit(fileread('${PROJECT}/config/impairmentlist.txt'),'\n');
    numfiles = length(filelist);
    [thresholdnoise, fs]=audioread('${THRESHOLDNOISE}');
    if fs ~= 48000
      thresholdnoise = resample(thresholdnoise, 48000, fs);
    end
    for i=1:numfiles
      if ~isempty(filelist{i})
        filename=filelist{i};
        [signal, fs]=audioread(filename);
        if fs ~= 48000
          signal = resample(signal, 48000, fs);
        end
        thresholdoffset=floor(rand(1)*(size(thresholdnoise,1)-size(signal,1)-1));
        signal = signal + thresholdnoise(1+thresholdoffset:size(signal,1)+thresholdoffset,:);
        audiowrite(filename, signal, 48000, 'BitsPerSample', 32);
        printf('.');
      end
    end
    printf('\nfinished\n');" || error "applying threshold simulating noise"
fi

# Extract features
fade "${PROJECT}" features "$FEATURESDIR" "$INDIVIDUAL" || error "extracting features"

# Remove corpus/processing
[ -e "${PROJECT}/corpus" ] && rm -r "${PROJECT}/corpus"
[ -e "${PROJECT}/processing" ] && rm -r "${PROJECT}/processing"

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
  sed -i "s/^CONDITION_CODE=.*$/CONDITION_CODE='${CONDITION_CODE}'/g" "${PROJECT}/config/corpus/format.cfg"
fi
fade "${PROJECT}" corpus-format || error "formatting corpus"

# Training
fade "${PROJECT}" training $TRAININGOPTIONS || error "training"

# Recognition
fade "${PROJECT}" recognition $RECOGNITIONOPTIONS || error "recognition"

# Delete features
[ -e "${PROJECT}/features" ] && rm -r "${PROJECT}/features"

# Evaluation
fade "${PROJECT}" evaluation || error "evaluating results"

# Delete training and recognition data
[ -e "${PROJECT}/training" ] && rm -r "${PROJECT}/training"
[ -e "${PROJECT}/recognition" ] && rm -r "${PROJECT}/recognition"

case "$SIMMODE" in
  coarse|medium)
  # Evaluate quick simulation to find point of interest

  POI=$(cat "${PROJECT}/evaluation/summary" | \
        sed -E 's/.*_([^_]*)$/\1/g' | sed -E 's/^(snr)?\+?//g' | \
        cut -d' ' -f1,2,3 | sort -n | \
        awk -F' ' -vt="${QSIM_THRESHOLD}" '{x1=$1;y1=$3/$2;if (y1>t) {if (NR>1) {printf "%.0f",x2+(x2-x1)/(y2-y1)*(t-y2)} exit} x2=x1;y2=y1}')

  if [ -z "${POI}" ]; then
    echo -e "\nPOI NOT FOUND\n"
  else
    echo -e "\nPOI found: ${POI}\n"
    echo "${POI}" > "${PROJECT}/poi"
  fi
  ;;
  precise)
    fade "${PROJECT}" figures || error "figures"
  ;;
esac

# For big (>1000) simulation experiments delete config and evaluation data as well
#[ -e "${PROJECT}/config" ] && rm -r "${PROJECT}/config"
#[ -e "${PROJECT}/evaluation" ] && rm -r "${PROJECT}/evaluation"

# Save the project to disk
mv "${PROJECT}" "${PROJECTDIR}" || error "saving project"

[ -e "${WORKDIR}" ] && rm -rf "${WORKDIR}"

