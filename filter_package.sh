#!/bin/bash -u

# ./filter_package.sh WORKER_ID PACKAGE_NAME

WORKER=$1
PACKAGE_NAME=$2

docker run -i --rm \
    -v $PWD/is_c_package.py:/is_c_package.py \
    bintoo \
    python /is_c_package.py "$PACKAGE_NAME"
NOT_C_PACKAGE=$?
if [ $NOT_C_PACKAGE -eq 0 ]; then
    echo $PACKAGE_NAME >> "listing.amd64.c.$WORKER"
fi

