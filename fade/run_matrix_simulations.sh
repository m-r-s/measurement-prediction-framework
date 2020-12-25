#!/bin/bash

DIR=$(cd "$( dirname "$0" )" && pwd)

MEASUREMENTS=(
  matrix,unaided-default,icra1,65
  matrix,linear,id-default,icra1,65
  matrix,compressive,id-default,icra1,65
  matrix,full,id-default,icra1,65
  matrix,unaided-default,icra5.250,65
  matrix,linear,id-default,icra5.250,65
  matrix,compressive,id-default,icra5.250,65
  matrix,full,id-default,icra5.250,65
  matrix,unaided-default,quiet,65
  matrix,linear,id-default,quiet,65
  matrix,compressive,id-default,quiet,65
  matrix,full,id-default,quiet,65
)
FEATURES='hzappp'

# Data folder prefix
DATAPREF="${DIR}/matrix-data/"
mkdir -p "$DATAPREF"

# Tested subjects
# ID-<left/right>
INDIVIDUALS=(
  listener01-l
  listener02-r
  listener03-l
  listener05-l
  listener06-r
  listener07-l
  listener08-l
  listener09-l
  listener10-l
  listener12-l
  listener14-r
  listener15-r
  listener16-l
  listener17-r
  listener18-r
  listener19-r
  listener20-l
  listener21-l
)
INDIVIDUALIZATIONS=(AD AG A)

NUM_SIMULATIONS=$[${#INDIVIDUALS[@]} * ${#MEASUREMENTS[@]} * ${#INDIVIDUALIZATIONS[@]}]
COUNT=0
for ((I=0;$I<${#INDIVIDUALS[@]};I++)); do
  for ((J=0;$J<${#MEASUREMENTS[@]};J++)); do
    for ((K=0;$K<${#INDIVIDUALIZATIONS[@]};K++)); do
      COUNT=$[${COUNT} + 1]
      CONDITIONCODE=($(echo "${MEASUREMENTS[$J]}" | tr '-' ' '))
      CONDITION=($(echo "${CONDITIONCODE[0]}" | tr ',' ' '))
      PARAMETERS=($(echo "${CONDITIONCODE[1]}" | tr ',' ' '))
      MEASUREMENT="${CONDITION[0]}"
      INDIVIDUAL="${INDIVIDUALS[$I]}"
      EAR="${INDIVIDUAL: -1}"
      INDIVIDUALIZATION="${INDIVIDUALIZATIONS[$K]}"
      
      STARTTIME=$(date +%s)
      echo "SIMULATION ${COUNT}/${NUM_SIMULATIONS}: Start ${MEASUREMENTS[$J]} with ${INDIVIDUAL} ${INDIVIDUALIZATION}"

      # First run to find approximate POI
      PREFIX="${DATAPREF}prep1-"
      SIMMODE="coarse"
      SIMRANGE=""
      PROJECTDIR="${PREFIX}${INDIVIDUAL}-M${MEASUREMENTS[$J]}-F${FEATURES}-I${INDIVIDUALIZATION}"

      case "$MEASUREMENT" in
        sweep)
          SIMRANGE="-10:10:120"
        ;;
        sweepinnoise)
          SIMRANGE="[-10:10:120]-65"
        ;;
        matrix)
          SIMRANGE="[0:10:120]-${PARAMETERS[2]}"
        ;;
      esac

      # Run first simulation
      echo "START ${SIMMODE} SIMULATION on '${PROJECTDIR}'"
      "${DIR}/fade_simulate.sh" "$PROJECTDIR" "${MEASUREMENTS[$J]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "$INDIVIDUALIZATION" "$INDIVIDUAL" "$EAR"
      # Get POI
      POI=""
      [ -e "${PROJECTDIR}/poi" ] && POI=$(cat "${PROJECTDIR}/poi")
      if [ -z "$POI" ]; then
        echo "SIMULATION ${COUNT}/${NUM_SIMULATIONS}: ${SIMMODE} SRT NOT FOUND - SKIP!"
        exit 1
      fi
      echo "SIMULATION ${COUNT}/${NUM_SIMULATIONS}: Found ${SIMMODE} SRT ${POI} after $[$(date +%s)-${STARTTIME}]s"

      # Second run to find better estimate of POI
      PREFIX="${DATAPREF}prep2-"
      SIMMODE="medium"
      SIMRANGE=""
      PROJECTDIR="${PREFIX}${INDIVIDUAL}-M${MEASUREMENTS[$J]}-F${FEATURES}-I${INDIVIDUALIZATION}"
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
      
      # Run second simulation
      echo "START ${SIMMODE} SIMULATION on '${PROJECTDIR}'"
      "${DIR}/fade_simulate.sh" "$PROJECTDIR" "${MEASUREMENTS[$J]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "$INDIVIDUALIZATION" "$INDIVIDUAL" "$EAR"
      # Get POI
      POI=""
      [ -e "${PROJECTDIR}/poi" ] && POI=$(cat "${PROJECTDIR}/poi")
      if [ -z "$POI" ]; then
        echo "SIMULATION ${COUNT}/${NUM_SIMULATIONS}: ${SIMMODE} SRT NOT FOUND - SKIP!"
        exit 1
      fi
      echo "SIMULATION ${COUNT}/${NUM_SIMULATIONS}: Found ${SIMMODE} SRT ${POI} after $[$(date +%s)-${STARTTIME}]s"

      # Run actual simulation
      PREFIX="${DATAPREF}run-"
      SIMMODE="precise"
      SIMRANGE=""
      PROJECTDIR="${PREFIX}${INDIVIDUAL}-M${MEASUREMENTS[$J]}-F${FEATURES}-I${INDIVIDUALIZATION}"
      case "$MEASUREMENT" in
        sweep)
          SIMRANGE="[-15:3:6]+${POI}"
        ;;
        sweepinnoise)
          SIMRANGE="[-15:3:6]+${POI}"
        ;;
        matrix)
          SIMRANGE="[-12:2:8]+${POI}"
        ;;
      esac

      # Run final simulation
      echo "START ${SIMMODE} SIMULATION on '${PROJECTDIR}'"
      "${DIR}/fade_simulate.sh" "$PROJECTDIR" "${MEASUREMENTS[$J]}" "$SIMRANGE" "$SIMMODE" "$FEATURES" "$INDIVIDUALIZATION" "$INDIVIDUAL" "$EAR"
      SRT=$(tail -n+2 "${PROJECTDIR}/figures/table.txt" | tr -s ' ' | cut -d' ' -f 2 | tr -d '\n')
      if [ -z "$SRT" ]; then
        echo "SIMULATION ${COUNT}/${NUM_SIMULATIONS}: ${SIMMODE} SRT NOT FOUND - SKIP!"
        exit 1
      fi
      echo "SIMULATION ${COUNT}/${NUM_SIMULATIONS}: Found ${SIMMODE} SRT ${SRT} in $[$(date +%s)-${STARTTIME}]s"
      echo -e "\n\n"
    done
  done
done 2>&1 | tee -a simulation.log | grep "^SIMULATION "

# Collect data for evaluation
collect_tables.sh "$DATAPREF" > ../evaluation/matrix_simulated_data.txt
