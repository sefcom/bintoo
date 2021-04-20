#!/bin/bash -eu

O="$1"
PKG="$2"

mkdir -p $PWD/out-$O
rm -f $PWD/out-$O/Packages
docker run -i --rm -v $PWD/out-$O:/shared -v $PWD/build.sh:/build.sh zardus/bintoo /build.sh /shared/O$O "-g -O$O -fcf-protection=none -fno-eliminate-unused-debug-types -frecord-gcc-switches" "$PKG" 
