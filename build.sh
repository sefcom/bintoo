#!/bin/bash

PKG="$1"
FLAGS="$2 -pipe"
DST="$3"

mkdir -p "$DST/$PKG"

# set up build options
sed -i -e "s/^COMMON_FLAGS.*/COMMON_FLAGS=\"$FLAGS\"/" /etc/portage/make.conf
echo 'FEATURES="nostrip getbinpkg buildpkg -ipc-sandbox -network-sandbox -pid-sandbox"' >> /etc/portage/make.conf
echo 'PORTAGE_BINHOST="file:///var/cache/binpkgs"' >> /etc/portage/make.conf

# sync if needed
[ ! -e /var/db/repos/gentoo ] && emerge --sync && emerge --update --deep --with-bdeps=y --newuse @world

# build
( USE="systemd X gitea" emerge --autounmask y --autounmask-continue y --autounmask-license y --autounmask-write y --ask n $PKG 2>&1 && echo BUILDER:SUCCESS || echo BUILDER:FAILED ) | tee "$DST/$PKG.buildlog"

# an analogue of this is done by the buildpkg above
#qlist "$PKG" > "$DST/$PKG/listing.txt"

# copy out the files
#qlist "$PKG" | xargs file | grep ELF | cut -d: -f1 | while IFS="" read -r ELF
#do
#	cp -a $ELF $DST/$PKG/${ELF//\//:}
#done
