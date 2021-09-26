#!/bin/bash -eu

O="$1"
PKG="$2"
TEMP_PACKAGES=$(tempfile)

mkdir -p $PWD/out-$O/O$O
rm -f $PWD/out-$O/O$O/Packages
touch $PWD/out-$O/O$O/Packages_merged
TEMP_PACKAGES_FILENAME=$(basename $TEMP_PACKAGES)
cp $PWD/out-$O/O$O/Packages_merged $TEMP_PACKAGES
docker run -i --rm \
    -v $PWD/out-$O:/shared \
    -v $PWD/build.sh:/build.sh \
    -v $TEMP_PACKAGES:/shared/O$O/Packages \
    zardus/bintoo \
    /build.sh /shared/O$O "-g -O$O -fcf-protection=none -fno-eliminate-unused-debug-types -frecord-gcc-switches" "$PKG" "$TEMP_PACKAGES_FILENAME"
echo "Calling merge_package_index.py"
./merge_package_index.py $PWD/out-$O/O$O/$TEMP_PACKAGES_FILENAME $PWD/out-$O/O$O/Packages_merged
echo "Removing temporary files"
rm -f $TEMP_PACKAGES
rm -f $PWD/out-$O/O$O/$TEMP_PACKAGES_FILENAME
