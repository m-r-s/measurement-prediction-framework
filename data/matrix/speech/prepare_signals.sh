#!/bin/bash
TARGET="default"
mkdir -p "${TARGET}"
ls -1 source/ | while read line; do
  sox "source/$line" -b 32 -r 48000 "${TARGET}/$line"
done

