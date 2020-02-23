#!/bin/bash

# Get the directory this script is stored in and its name
DIR=$(cd "$( dirname "$0" )" && pwd)
SCN=$(basename "$0")

if [ $# -lt 7 ]; then
  echo "Usage: $0 PREFIX MEASUREMENTSTRING IMPAIRMENT SIMRANGE SIMMODE FEATURES [FEATUREOPTION1] [FEATUREOPTION2] ..."
  echo ""
  exit 1
fi

error() {
  echo "error: $1"
  exit 1
}

# Get arguments
PREFIX="$1"
MEASUREMENTSTRING="$2"
IMPAIRMENT="$3"
SIMRANGE="$4"
SIMMODE="$5"
FEATURES="$6"
shift 6
FEATUREOPTIONS=("$@")

case "$SIMMODE" in
  fast)
    TRAININGSAMPELSPERMODEL=12
    RECOGNITIONDECISIONS=100
    # [STATES] [SILENCE_STATES] [MIXTURES] [ITERATIONS] [UPDATES] [PRUNINGS] [BINARY]
    TRAININGOPTIONS="4 4 1 4 mvwt 0 1"
    RECOGNITIONOPTIONS="0 50 1"
    FEATURESMODE="${FEATURES}-reduced"
  ;;
  full)
    TRAININGSAMPELSPERMODEL=96
    RECOGNITIONDECISIONS=600
    # [STATES] [SILENCE_STATES] [MIXTURES] [ITERATIONS] [UPDATES] [PRUNINGS] [BINARY]
    TRAININGOPTIONS="8 6 1 8 mvwt 0 1"
    MATCHEDSNRS=0
    RECOGNITIONOPTIONS="0 200 1"
    FEATURESMODE="${FEATURES}-full"
  ;;
esac

PROJECTDIR="${PREFIX}M${MEASUREMENTSTRING}-I${IMPAIRMENT}-S${SIMMODE}-F${FEATURES}"

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
PROCESSINGDIR="${DIR}/processing/${PROCESSING}/"
FEATURESDIR="${DIR}/features/${FEATURESMODE}/"

# Set up experiment
case "$MEASUREMENT" in
  sweep)
    QSIM_THRESHOLD=0.875
    fade "$PROJECTDIR" corpus-stimulus "$[${TRAININGSAMPELSPERMODEL}*1]" "$[${RECOGNITIONDECISIONS}/2]" || error "creating project"
    FREQUENCY=${PARAMETERS[0]}
    EAR=${PARAMETERS[1]}
    cp -L "${DIR}/stimulus/"* "${PROJECTDIR}/config/corpus/matlab" || error "copying stimulus generation files"
    cp -L "${DIR}/stimulus/control_"* "${PROJECTDIR}/config/figures/matlab" || error "copying stimulus control files"
    echo "function generate(target_dir, samples, seed, verbose)
          mkdir(target_dir);
          classes = {0 1};
          % Sweep in noise detection
          funname = 'gensweep';
          values = ${SIMRANGE};
          generate_conditions(target_dir, funname, classes, ...
            num2cell(values), samples, {'${FREQUENCY},${EAR}'}, seed, verbose);
          " > "${PROJECTDIR}/config/corpus/matlab/generate.m"
  ;;
  sweepinnoise)
    QSIM_THRESHOLD=0.875
    fade "$PROJECTDIR" corpus-stimulus "$[${TRAININGSAMPELSPERMODEL}*1]" "$[${RECOGNITIONDECISIONS}/2]" || error "creating project"
    FREQUENCY=${PARAMETERS[0]}
    EAR=${PARAMETERS[1]}
    cp -L "${DIR}/stimulus/"* "${PROJECTDIR}/config/corpus/matlab" || error "copying stimulus generation files"
    cp -L "${DIR}/stimulus/control_"* "${PROJECTDIR}/config/figures/matlab" || error "copying stimulus control files"
    echo "function generate(target_dir, samples, seed, verbose)
          mkdir(target_dir);
          classes = {0 1};
          % Sweep in noise detection
          funname = 'gensweepinnoise';
          values = ${SIMRANGE};
          generate_conditions(target_dir, funname, classes, ...
            num2cell(values), samples, {'${FREQUENCY},${EAR}'}, seed, verbose);
          " > "${PROJECTDIR}/config/corpus/matlab/generate.m"
  ;;
  matrix)
    QSIM_THRESHOLD=0.5
    TALKER="${PARAMETERS[0]}"
    NOISEMASKER="${PARAMETERS[1]}"
    NOISELEVEL="${PARAMETERS[2]}"
    EAR="${PARAMETERS[3]}"
    fade "$PROJECTDIR" corpus-matrix "$[${TRAININGSAMPELSPERMODEL}*10]" "$[${RECOGNITIONDECISIONS}/5]" || error "creating project"
    cp -L "${DIR}/matrix/speech/${TALKER}/"*".wav" "${PROJECTDIR}/source/speech/" || error "copying speech files"
    cp -L "${DIR}/matrix/maskers/${NOISEMASKER}.wav" "${PROJECTDIR}/source/noise/" || error "copying masker file"
    (cd "${PROJECTDIR}/source" && find -iname '*.wav') > "${PROJECTDIR}/config/sourcelist.txt"
    # Adjust level and resample to 48kHz
    echo "Adjust levels, resample, and select channels"
    octave-cli --quiet --eval "ear = '${EAR}';
      filelist = strsplit(fileread('${PROJECTDIR}/config/sourcelist.txt'),'\n');
      numfiles = length(filelist);
      for i=1:numfiles
        if ~isempty(filelist{i})
          filename = ['${PROJECTDIR}/source/' filelist{i}];
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
  fade "$PROJECTDIR" processing "$PROCESSINGDIR" || error "processing"
fi

# Apply threshold simulating noise
if [ ! "$IMPAIRMENT" == "none" ]; then
  echo "Apply threshold simulating noise"
  if [ -e "${PROJECTDIR}/processing" ]; then
      (cd "${PROJECTDIR}/processing" && find "$PWD" -iname '*.wav') > "${PROJECTDIR}/config/impairmentlist.txt" || error "finding processed files"
  elif [ -e "${PROJECTDIR}/corpus" ]; then
      (cd "${PROJECTDIR}/corpus" && find "$PWD" -iname '*.wav') > "${PROJECTDIR}/config/impairmentlist.txt" || error "finding corpus files"
  else
      error "finding files for applying threshold simulating noise"
  fi
  octave-cli --quiet --eval "
    filelist = strsplit(fileread('${PROJECTDIR}/config/impairmentlist.txt'),'\n');
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
fade "$PROJECTDIR" features "$FEATURESDIR" ${FEATUREOPTIONS[@]} || error "extracting features"

# Format corpus (determine training/testing combinations)
if [ "$SIMMODE" == "fast" ]; then
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
  fast)
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
  full)
    fade "$PROJECTDIR" figures
  ;;
esac

