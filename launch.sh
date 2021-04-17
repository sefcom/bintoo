#!/bin/bash -eu

O="$1"
PKG="$2"

VOLPATH=/var/cache/binpkgs

mkdir -p $PWD/out-$O
rm -f $PWD/out-$O/Packages
docker run -i --rm -v $PWD/out-$O:$VOLPATH -v $PWD/build.sh:/build.sh gbuilder /build.sh "$PKG" "-g -O$O -fcf-protection=none -fno-eliminate-unused-debug-types -frecord-gcc-switches" $VOLPATH
