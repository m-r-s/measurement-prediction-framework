#!/bin/bash
[ -e "configuration" ] && rm -r "configuration"
cp "configuration.m" "../../../platt/tools/configuration.m" || exit 1
(cd "../../../platt/tools/" && ./update_configuration.m) || exit 1
cp -r "../../../platt/src/configuration" "configuration" || exit 1

