#!/bin/bash

DIR=$(cd "$( dirname "$0" )" && pwd)

export PLATT_PATH="${DIR}/platt-bin"

# Data folder prefix
DATAPREF="${DIR}/simulation-data/"
mkdir -p "$DATAPREF"

IMPAIRMENTS=('none')
MEASUREMENTS=('sweep,none-1000,l' 'sweep,openMHA-1000,l' 'sweepinnoise,none-1000,l' 'sweepinnoise,openMHA-1000,l' 'matrix,none-default,quiet,0,b' 'matrix,openMHA-default,quiet,0,b' 'matrix,none-default,whitenoise,65,b' 'matrix,openMHA-default,whitenoise,65,b')

# Features
FEATURES='sgbfb-kain'

# Individuals
INDIVIDUALS=(
  bisgaard-0-1
)

for ((I=0;$I<${#INDIVIDUALS[@]};I++)); do
  for ((J=0;$J<${#MEASUREMENTS[@]};J++)); do
    for ((K=0;$K<${#IMPAIRMENTS[@]};K++)); do
      CONDITIONCODE=($(echo "${MEASUREMENTS[$J]}" | tr '-' ' '))
      CONDITION=($(echo "${CONDITIONCODE[0]}" | tr ',' ' '))
      PARAMETERS=($(echo "${CONDITIONCODE[1]}" | tr ',' ' '))
      MEASUREMENT="${CONDITION[0]}"
      INDIVIDUAL="${INDIVIDUALS[$I]}"
      IMPAIRMENT="${IMPAIRMENTS[$K]}"

      STARTTIME=$(date +%s)

      # First run to find approximate POI
      PREFIX="${DATAPREF}prep1-"
      SIMMODE="coarse"
      SIMRANGE=""
      PROJECTDIR="${PREFIX}${INDIVIDUAL}-M${MEASUREMENTS[$J]}-F${FEATURES}-I${IMPAIRMENTS}"
      case "$MEASUREMENT" in
        sweep)
          SIMRANGE="-10:10:120"
        ;;
        sweepinnoise)
          SIMRANGE="-10:10:120"
        ;;
        matrix)
          SIMRANGE="[0:10:100]-${PARAMETERS[2]}"
        ;;
      esac

      # Run simulation
      echo "START ${SIMMODE} SIMULATION on '${PROJECTDIR}'"
      "${DIR}/fade_simulate.sh" "$PROJECTDIR" "${MEASUREMENTS[$J]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "$INDIVIDUAL" "${IMPAIRMENT}"
      # Get POI
      POI=""
      [ -e "${PROJECTDIR}/poi" ] && POI=$(cat "${PROJECTDIR}/poi")
      if [ -z "$POI" ]; then
        echo "POI NOT FOUND - SKIP MEASUREMENT!"
        continue
      fi

      echo "SIMULATION TIME: $[$(date +%s)-${STARTTIME}] seconds elapsed"

      # Second run to find better estimate of POI
      PREFIX="${DATAPREF}prep2-"
      SIMMODE="medium"
      SIMRANGE=""
      PROJECTDIR="${PREFIX}${INDIVIDUAL}-M${MEASUREMENTS[$J]}-F${FEATURES}-I${IMPAIRMENTS}"
      case "$MEASUREMENT" in
        sweep)
          SIMRANGE="[-15:5:15]+${POI}"
        ;;
        sweepinnoise)
          SIMRANGE="[-15:5:15]+${POI}"
        ;;
        matrix)
          SIMRANGE="[-18:6:18]+${POI}"
        ;;
      esac
      # Run simulation
      echo "START ${SIMMODE} SIMULATION on '${PROJECTDIR}'"
      "${DIR}/fade_simulate.sh" "$PROJECTDIR" "${MEASUREMENTS[$J]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "$INDIVIDUAL" "${IMPAIRMENT}"
      # Get POI
      POI=""
      [ -e "${PROJECTDIR}/poi" ] && POI=$(cat "${PROJECTDIR}/poi")
      if [ -z "$POI" ]; then
        echo "POI NOT FOUND - SKIP MEASUREMENT!"
        continue
      fi

      echo "SIMULATION TIME: $[$(date +%s)-${STARTTIME}] seconds elapsed"

      # Run actual simulation
      PREFIX="${DATAPREF}run-"
      SIMMODE="precise"
      SIMRANGE=""
      PROJECTDIR="${PREFIX}${INDIVIDUAL}-M${MEASUREMENTS[$J]}-F${FEATURES}-I${IMPAIRMENTS}"
      case "$MEASUREMENT" in
        sweep)
          SIMRANGE="[-15:3:6]+${POI}"
        ;;
        sweepinnoise)
          SIMRANGE="[-15:3:6]+${POI}"
        ;;
        matrix)
          SIMRANGE="[-15:3:9]+${POI}"
        ;;
      esac
      # Run simulation
      echo "START ${SIMMODE} SIMULATION on '${PROJECTDIR}'"
      "${DIR}/fade_simulate.sh" "$PROJECTDIR" "${MEASUREMENTS[$J]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "$INDIVIDUAL" "${IMPAIRMENT}"
      # Show result
      echo "SIMULATION FINISHED"
      cat "${PROJECTDIR}/figures/table.txt"
      echo -e "\n"
      echo "SIMULATION TIME: finished after $[$(date +%s)-${STARTTIME}] seconds"
      echo -e "\n\n"
    done
  done
done

# Collect data for evaluation
collect_tables.sh "$DATAPREF" | sort | column -t | tee results.txt
