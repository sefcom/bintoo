#!/bin/bash

PKG="$1"
FLAGS="$2 -pipe"
DST="$3"

mkdir -p "$DST/$PKG"

# set up build options
echo 'FEATURES="nostrip -ipc-sandbox -network-sandbox -pid-sandbox"' >> /etc/portage/make.conf
sed -i -e "s/^COMMON_FLAGS.*/COMMON_FLAGS=\"$FLAGS\"/" /etc/portage/make.conf

cat /etc/portage/make.conf

# sync if needed
[ -e /var/db/repos/gentoo ] || emerge --sync

# build
( emerge $PKG 2>&1 && echo BUILDER:SUCCESS || echo BUILDER:FAILED ) | tee "$DST/$PKG/build.log"
qlist "$PKG" > "$DST/$PKG/listing.txt"

# copy out the files
qlist "$PKG" | xargs file | grep ELF | cut -d: -f1 | while IFS="" read -r ELF
do
	cp -a $ELF $DST/$PKG/${ELF//\//:}
done
