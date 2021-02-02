#!/bin/bash

SOURCE="platt"
EXPANSIONS=($(seq 8))

for EXPANSION in ${EXPANSIONS[@]}; do
  TARGET="platt${EXPANSION}"
  if [ -e "${TARGET}" ]; then
    rm -r "${TARGET}" || exit 1
  fi
  mkdir -p "${TARGET}" || exit 1
  sed "s/^expansion_factor[ ]*=.*/expansion_factor = ${EXPANSION}/g" "${SOURCE}/configuration.m" > "${TARGET}/configuration.m" || exit 1
  cp "${TARGET}/configuration.m" "../../platt/tools/configuration.m" || exit 1
  (cd "../../platt/tools/" && ./update_configuration.m) || exit 1
  cp -r "../../platt/src/configuration" "${TARGET}/configuration" || exit 1
  cp -t "${TARGET}" "${SOURCE}/batch_process" "${SOURCE}/platt.cfg"
done

