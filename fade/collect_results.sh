#!/bin/bash

DIR="${1}"

(echo "Measurement Condition Processing Impairment Threshold";cd "$DIR" && collect_tables.sh . | \
  tail -n+2 | \
  sed -E 's/^.*-M([^-]*)-([^ ]*)-P(.*)-I(.*)-Sfull-F[^\t ]*[\t ]*[^ ]*[ ]* ([^ ]*) .*$/\1 \2 \3 \4 \5/g' | \
  sort -k4,4 -k2,2n -k1,1 \
) | column -t
