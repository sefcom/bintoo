#!/bin/bash -eu

O="$1"
PKG="$2"

docker run -i --rm -v $PWD:/g gbuilder /g/build.sh "$PKG" "-g -O$O -fcf-protection=none -fno-eliminate-unused-debug-types" /g/out-$O
