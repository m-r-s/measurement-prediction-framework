#!/bin/bash

FILE="$1"
PORT="$2"
DELETE="$3"
if [ -e "${FILE}" ]; then
  mplayer -quiet -channels 4 -ao jack:port=${PORT} "${FILE}"
  if [ "${DELETE}" == 1 ]; then
    rm "${FILE}"
  fi
fi
