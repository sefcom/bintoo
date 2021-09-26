#!/bin/bash

DST=$1
FLAGS="$2 -pipe"
PKG="$3"
OUTPUT_PACKAGES="$4"

mkdir -p $DST/$(dirname $PKG)
(
	echo "BINTOO:DESTINATION: $DST"
	echo "BINTOO:FLAGS: $FLAGS"
	echo "BINTOO:PKG: $PKG"

	mkdir -p /var/cache/binpkgs
	mkdir -p $DST/$(dirname $PKG)
	if [ -e /shared ]
	then
	#	cp $DST/Packages /var/cache/binpkgs
	#	for category in /var/db/repos/gentoo/*/
	#	do
	#		c=$(basename $category)
	#		mkdir -p $DST/$c
	#		ln -s $DST/$c /var/cache/binpkgs/
	#	done
		echo nameserver 1.1.1.1 > /etc/resolv.conf
	fi

	# set up build options
	sed -i -e "s/^COMMON_FLAGS.*/COMMON_FLAGS=\"$FLAGS\"/" /etc/portage/make.conf
	echo 'FEATURES="nostrip getbinpkg buildpkg -ipc-sandbox -network-sandbox -pid-sandbox"' >> /etc/portage/make.conf
	echo 'PORTAGE_BINHOST="file://'$DST'"' >> /etc/portage/make.conf
	echo 'FETCHCOMMAND="curl -o \"\${DISTDIR}/\${FILE}\" \"\${URI}\""' >> /etc/portage/make.conf
	echo 'RESUMECOMMAND="curl -C - -o \"\${DISTDIR}/\${FILE}\" \"\${URI}\""' >> /etc/portage/make.conf

	# sync if needed
	[ ! -e /var/db/repos/gentoo ] && emerge --sync && emerge --update --deep --with-bdeps=y --newuse @world

	# build
	USE="opengl gui widgets systemd X gitea -elogind" emerge --binpkg-respect-use=n --newuse --autounmask y --autounmask-continue y --autounmask-license y --autounmask-write y --ask n $PKG
	EMERGE_CODE=$?
	echo "BINTOO:RETURNCODE: $EMERGE_CODE"

	echo "BINTOO:LOG: $DST/$PKG.buildlog"

	shopt -s nullglob
	for tarball in /var/cache/binpkgs/*-*/*.tbz2
	do
		echo $tarball
		dst_tarball=$DST/$(basename $(dirname $tarball))/$(basename $tarball)
		mkdir -p $(dirname $dst_tarball)
		[ -f $dst_tarball ] && echo "$dst_tarball: already exists" || cp -v $tarball $dst_tarball
	done
    cp -v /var/cache/binpkgs/Packages $DST/$OUTPUT_PACKAGES
	[ $EMERGE_CODE -eq 0 ] && echo BINTOO:SUCCESS || echo BINTOO:FAILED
	sleep 2
	exit $EMERGE_CODE
) 2>&1| tee "$DST/$PKG.buildlog"
