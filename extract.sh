#!/bin/bash

DST=$1
TARBALL=$2

mkdir -p /tmp/extract-$$
cd /tmp/extract-$$

tar xf $TARBALL

find . -type f | xargs file | grep ":.*ELF" | cut -d: -f1 | while IFS="" read -r ELF
do
	mkdir -p $DST/$(dirname $ELF)
	cp -av $ELF $DST/$ELF
done

rm -rf /tmp/extract-$$
