#!/bin/bash

DIR=$(cd "$( dirname "$0" )" && pwd)

MEASUREMENTS=(
  sweepinnoise,unaided-500
  sweepinnoise,unaided-1000
  sweepinnoise,unaided-2000
  sweepinnoise,unaided-4000
)
FEATURES='hzappp'

# Data folder prefix
DATAPREF="${DIR}/tin-data/"
mkdir -p "$DATAPREF"

# Profile subjects
INDIVIDUALS=(P-11-{1,2,3,4,5,6,7,8,9,10,12,14,16,18,20,22,24,26})

for ((I=0;$I<${#INDIVIDUALS[@]};I++)); do
  for ((J=0;$J<${#MEASUREMENTS[@]};J++)); do
    CONDITIONCODE=($(echo "${MEASUREMENTS[$J]}" | tr '-' ' '))
    CONDITION=($(echo "${CONDITIONCODE[0]}" | tr ',' ' '))
    PARAMETERS=($(echo "${CONDITIONCODE[1]}" | tr ',' ' '))
    MEASUREMENT="${CONDITION[0]}"
    INDIVIDUAL="${INDIVIDUALS[$I]}"
    STARTTIME=$(date +%s)

    # First run to find approximate POI
    PREFIX="${DATAPREF}prep1-"
    SIMMODE="coarse"
    SIMRANGE=""
    PROJECTDIR="${PREFIX}${INDIVIDUAL}-M${MEASUREMENTS[$J]}-F${FEATURES}"
    case "$MEASUREMENT" in
      sweep)
        SIMRANGE="-10:10:110"
      ;;
      sweepinnoise)
        SIMRANGE="[50:10:120]-65"
      ;;
      matrix)
        SIMRANGE="[0:10:100]-${PARAMETERS[2]}"
      ;;
    esac
    # Run simulation
    echo "START ${SIMMODE} SIMULATION on '${PROJECTDIR}'"
    "${DIR}/fade_simulate.sh" "$PROJECTDIR" "${MEASUREMENTS[$J]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "AD" "$INDIVIDUAL" "l"
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
    PREFIX="${DATAPREF}prep2-"
    SIMMODE="medium"
    SIMRANGE=""
    PROJECTDIR="${PREFIX}${INDIVIDUAL}-M${MEASUREMENTS[$J]}-F${FEATURES}"
    case "$MEASUREMENT" in
      sweep)
        SIMRANGE="[-15:5:15]+${POI}"
      ;;
      sweepinnoise)
        SIMRANGE="[-15:3:15]+${POI}"
      ;;
      matrix)
        SIMRANGE="[-15:5:15]+${POI}"
      ;;
    esac
    # Run simulation
    echo "START ${SIMMODE} SIMULATION on '${PROJECTDIR}'"
    "${DIR}/fade_simulate.sh" "$PROJECTDIR" "${MEASUREMENTS[$J]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "AD" "$INDIVIDUAL" "l"
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
    PREFIX="${DATAPREF}run-"
    SIMMODE="precise"
    SIMRANGE=""
    PROJECTDIR="${PREFIX}${INDIVIDUAL}-M${MEASUREMENTS[$J]}-F${FEATURES}"
    case "$MEASUREMENT" in
      sweep)
        SIMRANGE="[-15:3:6]+${POI}"
      ;;
      sweepinnoise)
        SIMRANGE="[-11:1:8]+${POI}"
      ;;
      matrix)
        SIMRANGE="[-15:3:6]+${POI}"
      ;;
    esac
    # Run simulation
    echo "START ${SIMMODE} SIMULATION on '${PROJECTDIR}'"
    "${DIR}/fade_simulate.sh" "$PROJECTDIR" "${MEASUREMENTS[$J]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "AD" "$INDIVIDUAL" "l"
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

# Get simulation data
collect_tables.sh "$DATAPREF" | tail -n+2 | tr -s ' ' | sed -E 's/^[^-]+-P-[0-9]+-([0-9]+)[^_]+[_]+([0-9]+).[^ ]+[ ]+([-0-9.]+).*$/\1 \2 \3/g' | sort -k1,1n -k2,2n > "${DIR}/features/hzappp-full/ul2tintable.txt"
