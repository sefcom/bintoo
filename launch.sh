#!/bin/bash -eu

WORKER="$1"
O="$2"
PKG="$3"
TEMP_PACKAGES=$(tempfile)

mkdir -p $PWD/out-$O-$WORKER/O$O
PKG_PATH=$(find . -path "*$PKG*.tbz2" || echo '')
if [ ! -z "${PKG_PATH}" ]; then
	echo "$PKG exists (@$PKG_PATH). Skip."
	exit 0
fi

# skip non C/C++ packages
IN_C_LISTING=$(grep "$PKG" listing.amd64.c || echo '')
if [ -z "$IN_C_LISTING" ]; then
	echo "$PKG is not a C/C++ package. Skip."
	exit 0
fi

# only build the ones that are totally missing
BUILDLOG_PATH=$PWD/out-$O-$WORKER/O$O/$PKG.buildlog
if [ -f $BUILDLOG_PATH ]; then
	exit 0
fi

rm -rf $PWD/out-$O-$WORKER/O$O/Packages
touch $PWD/out-$O-$WORKER/O$O/Packages_merged
TEMP_PACKAGES_FILENAME=$(basename $TEMP_PACKAGES)
cp $PWD/out-$O-$WORKER/O$O/Packages_merged $PWD/out-$O-$WORKER/O$O/Packages
docker run -i --rm \
    -v $PWD/out-$O-$WORKER:/shared \
    -v $PWD/build.sh:/build.sh \
    -v $PWD/hooks/hook_execve.so:/hook_execve.so \
    --privileged=true \
    bintoo \
    /build.sh /shared/O$O "-O$O" "$PKG" "$TEMP_PACKAGES_FILENAME"
echo "Calling merge_package_index.py"
./merge_package_index.py $PWD/out-$O-$WORKER/O$O/$TEMP_PACKAGES_FILENAME $PWD/out-$O-$WORKER/O$O/Packages_merged
echo "Removing temporary files"
rm -f $TEMP_PACKAGES
rm -f $PWD/out-$O-$WORKER/O$O/$TEMP_PACKAGES_FILENAME
