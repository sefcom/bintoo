#!/bin/bash -eu

WORKER="$1"
O="$2"
PKG="$3"
TEMP_PACKAGES=$(tempfile)

mkdir -p $PWD/out-$O-$WORKER/O$O
PKG_PATH=$(ls $PWD/out-$O-$WORKER/O$O/*/*.tbz2 | grep $PKG || echo '')
if [ ! -z "${PKG_PATH}" ]; then
	echo "$PKG exists (@$PKG_PATH). Skip."
	exit 0
fi
rm -f $PWD/out-$O-$WORKER/O$O/Packages
touch $PWD/out-$O-$WORKER/O$O/Packages_merged
TEMP_PACKAGES_FILENAME=$(basename $TEMP_PACKAGES)
cp $PWD/out-$O-$WORKER/O$O/Packages_merged $TEMP_PACKAGES
docker run -i --rm \
    -v $PWD/out-$O-$WORKER:/shared \
    -v $PWD/build.sh:/build.sh \
    -v $PWD/hooks/hook_execve.so:/hook_execve.so \
    -v $TEMP_PACKAGES:/shared/O$O/Packages \
    --privileged=true \
    bintoo \
    /build.sh /shared/O$O "-O$O" "$PKG" "$TEMP_PACKAGES_FILENAME"
echo "Calling merge_package_index.py"
./merge_package_index.py $PWD/out-$O-$WORKER/O$O/$TEMP_PACKAGES_FILENAME $PWD/out-$O-$WORKER/O$O/Packages_merged
echo "Removing temporary files"
rm -f $TEMP_PACKAGES
rm -f $PWD/out-$O-$WORKER/O$O/$TEMP_PACKAGES_FILENAME
