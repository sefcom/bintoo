#!/bin/bash

DST=$1
RAW_FLAGS=$2
FLAGS="$2 -fcf-protection=none -fno-eliminate-unused-debug-types -frecord-gcc-switches -pipe -fno-lto"
PKG="$3"
OUTPUT_PACKAGES="$4"

mkdir -p $DST/$(dirname $PKG)
(
	echo "BINTOO:DESTINATION: $DST"
	echo "BINTOO:RAW_FLAGS: $RAW_FLAGS"
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
	echo 'FEATURES="nostrip getbinpkg buildpkg -ipc-sandbox -network-sandbox -pid-sandbox -sandbox -usersandbox -userpriv"' >> /etc/portage/make.conf
	echo 'PORTAGE_BINHOST="file://'$DST'"' >> /etc/portage/make.conf
	echo 'FETCHCOMMAND="curl -o \"\${DISTDIR}/\${FILE}\" \"\${URI}\""' >> /etc/portage/make.conf
	echo 'RESUMECOMMAND="curl -C - -o \"\${DISTDIR}/\${FILE}\" \"\${URI}\""' >> /etc/portage/make.conf
	# limit the number of parallel jobs to avoid RAM exhaustion
	echo 'MAKEOPTS="--jobs 8 --load-average 9"' >> /etc/portage/make.conf

	# run emaint binhost --fix to ensure Packages file is complete
	echo "PKGDIR=$DST" >> /etc/portage/make.conf
	emaint binhost --fix
	sed -i '$ d' /etc/portage/make.conf

	# disable lto since it uses too much RAM
	echo "*/* lto" >> /etc/portage/package.use

	# sync if needed
	[ ! -e /var/db/repos/gentoo ] && emerge --sync && emerge --update --deep --with-bdeps=y --newuse @world

	# setup environment variables
	if [[ "$PKG" == *"emulation"* ]]; then
		echo "disable execve-hooks for emulation apps"
	else
		export LD_PRELOAD=/hook_execve.so
		export VARNAMES_ENABLE=true
		export VARNAMES_OPT=$RAW_FLAGS
		echo 'export LD_PRELOAD=/hook_execve.so' >> /etc/portage/bashrc
		echo 'export VARNAMES_ENABLE=true' >> /etc/portage/bashrc
		echo "export VARNAMES_OPT=$RAW_FLAGS" >> /etc/portage/bashrc
	fi

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
		cp -uv $tarball $dst_tarball
	done
	cp -v /var/cache/binpkgs/Packages $DST/$OUTPUT_PACKAGES
	[ $EMERGE_CODE -eq 0 ] && echo BINTOO:SUCCESS || echo BINTOO:FAILED
	sleep 2
	exit $EMERGE_CODE
) 2>&1| tee "$DST/$PKG.buildlog"
