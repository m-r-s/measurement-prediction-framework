#!/bin/bash

DIR=$(cd "$( dirname "$0" )" && pwd)

IMPAIRMENTS=('none')
PROCESSINGS=('none' 'openMHA_unaided')
MEASUREMENTS=('sweepinnoise-500,l' 'matrix-whitenoise,65,b')
FEATURES='sgbfb'
FEATUREOPTION='1.0'

for ((I=0;$I<${#IMPAIRMENTS[@]};I++)); do
  for ((K=0;$K<${#MEASUREMENTS[@]};K++)); do
    for ((J=0;$J<${#PROCESSINGS[@]};J++)); do
      MEASUREMENTPARAMETERS=($(echo "${MEASUREMENTS[$K]}" | tr '-' ' '))
      MEASUREMENT="${MEASUREMENTPARAMETERS[0]}"
      PARAMETERS=($(echo "${MEASUREMENTPARAMETERS[1]}" | tr ',' ' '))

      STARTTIME=$(date +%s)

      # First run to find approximate POI
      PREFIX="prep1-"
      SIMMODE="fast"
      SIMRANGE=""
      PROJECTDIR="${PREFIX}M${MEASUREMENTS[$K]}-P${PROCESSINGS[$J]}-I${IMPAIRMENTS[$I]}-S${SIMMODE}-F${FEATURES}"
      case "$MEASUREMENT" in
        sweep)
          SIMRANGE="-10:10:110"
        ;;
        sweepinnoise)
          SIMRANGE="-10:10:110"
        ;;
        matrix)
          SIMRANGE="[0:10:100]-${PARAMETERS[1]}"
        ;;
      esac
      # Run simulation
      echo "START FAST SIMULATION (1) on '${PROJECTDIR}'"
      "${DIR}/fade_simulate.sh" "$PREFIX" "${MEASUREMENTS[$K]}" "${PROCESSINGS[$J]}" "${IMPAIRMENTS[$I]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "$FEATUREOPTION"
      # Get POI
      POI=""
      [ -e "${PROJECTDIR}/poi" ] && POI=$(cat "${PROJECTDIR}/poi")
      if [ -z "$POI" ]; then
        echo "POI NOT FOUND - SKIP MEASUREMENT!"
        continue
      fi
      [ -e "${PROJECTDIR}/source" ] && rm -r "${PROJECTDIR}/source"
      [ -e "${PROJECTDIR}/corpus" ] && rm -r "${PROJECTDIR}/corpus"
      [ -e "${PROJECTDIR}/processing" ] && rm -r "${PROJECTDIR}/processing"
      [ -e "${PROJECTDIR}/features" ] && rm -r "${PROJECTDIR}/features"

      echo "SIMULATION TIME: $[$(date +%s)-${STARTTIME}] seconds elapsed"

      # Second run to find better estimate of POI
      PREFIX="prep2-"
      SIMMODE="fast"
      SIMRANGE=""
      PROJECTDIR="${PREFIX}M${MEASUREMENTS[$K]}-P${PROCESSINGS[$J]}-I${IMPAIRMENTS[$I]}-S${SIMMODE}-F${FEATURES}"
      case "$MEASUREMENT" in
        sweep)
          SIMRANGE="[-15:5:15]+${POI}"
        ;;
        sweepinnoise)
          SIMRANGE="[-15:5:15]+${POI}"
        ;;
        matrix)
          SIMRANGE="[-15:5:15]+${POI}"
        ;;
      esac
      # Run simulation
      echo "START FAST SIMULATION (2) on '${PROJECTDIR}'"
      "${DIR}/fade_simulate.sh" "$PREFIX" "${MEASUREMENTS[$K]}" "${PROCESSINGS[$J]}" "${IMPAIRMENTS[$I]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "$FEATUREOPTION"
      # Get POI
      POI=""
      [ -e "${PROJECTDIR}/poi" ] && POI=$(cat "${PROJECTDIR}/poi")
      if [ -z "$POI" ]; then
        echo "POI NOT FOUND - SKIP MEASUREMENT!"
        continue
      fi
      [ -e "${PROJECTDIR}/source" ] && rm -r "${PROJECTDIR}/source"
      [ -e "${PROJECTDIR}/corpus" ] && rm -r "${PROJECTDIR}/corpus"
      [ -e "${PROJECTDIR}/processing" ] && rm -r "${PROJECTDIR}/processing"
      [ -e "${PROJECTDIR}/features" ] && rm -r "${PROJECTDIR}/features"

      echo "SIMULATION TIME: $[$(date +%s)-${STARTTIME}] seconds elapsed"

      # Run actual simulation
      PREFIX="run1-"
      SIMMODE="full"
      SIMRANGE=""
      PROJECTDIR="${PREFIX}M${MEASUREMENTS[$K]}-P${PROCESSINGS[$J]}-I${IMPAIRMENTS[$I]}-S${SIMMODE}-F${FEATURES}"
      case "$MEASUREMENT" in
        sweep)
          SIMRANGE="[-15:3:6]+${POI}"
        ;;
        sweepinnoise)
          SIMRANGE="[-15:3:6]+${POI}"
        ;;
        matrix)
          SIMRANGE="[-15:3:6]+${POI}"
        ;;
      esac
      # Run simulation
      echo "START FULL SIMULATION on '${PROJECTDIR}'"
      "${DIR}/fade_simulate.sh" "$PREFIX" "${MEASUREMENTS[$K]}" "${PROCESSINGS[$J]}" "${IMPAIRMENTS[$I]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "$FEATUREOPTION"
      # Show result
      echo "SIMULATION FINISHED"
      cat "${PROJECTDIR}/figures/table.txt"
      [ -e "${PROJECTDIR}/source" ] && rm -r "${PROJECTDIR}/source"
      [ -e "${PROJECTDIR}/corpus" ] && rm -r "${PROJECTDIR}/corpus"
      [ -e "${PROJECTDIR}/processing" ] && rm -r "${PROJECTDIR}/processing"
      [ -e "${PROJECTDIR}/features" ] && rm -r "${PROJECTDIR}/features"
      echo -e "\n"
      echo "SIMULATION TIME: finished after $[$(date +%s)-${STARTTIME}] seconds"
      echo -e "\n\n"
    done
  done
done

"${DIR}/collect_results.sh" "$PWD" | tee results.txt
