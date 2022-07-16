#!/bin/bash

DST=$1
RAW_FLAGS=$2
FLAGS="$2 -g -fcf-protection=none -fno-eliminate-unused-debug-types -frecord-gcc-switches -pipe -fno-lto -fno-inline-functions -fno-inline-small-functions -fno-inline-functions-called-once -fno-inline"
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
	echo 'FETCHCOMMAND="curl -L -o \"\${DISTDIR}/\${FILE}\" \"\${URI}\""' >> /etc/portage/make.conf
	echo 'RESUMECOMMAND="curl -L -C - -o \"\${DISTDIR}/\${FILE}\" \"\${URI}\""' >> /etc/portage/make.conf
	# limit the number of parallel jobs to avoid RAM exhaustion
	echo 'MAKEOPTS="--jobs 8 --load-average 9"' >> /etc/portage/make.conf

	# remove binary package verification
	sed -i -e "s/self._verify =.*/self._verify = False/" /usr/lib/python3.10/site-packages/_emerge/Binpkg.py

	# force unused targets
	# bug: https://bugs.gentoo.org/767700
	# ref: https://www.reddit.com/r/Gentoo/comments/teody6/why_are_nearly_all_llvm_targets_forced_since_the/
	mkdir -p /etc/portage/profile/
	echo "sys-devel/llvm LLVM_TARGETS: X86 BPF -AArch64 -AMDGPU -ARM -AVR -Hexagon -Lanai -MSP430 -Mips -NVPTX -PowerPC -RISCV -Sparc -SystemZ -WebAssembly -XCore" >> /etc/portage/profile/package.use.force
	echo "sys-devel/clang LLVM_TARGETS: X86 BPF -AArch64 -AMDGPU -ARM -AVR -Hexagon -Lanai -MSP430 -Mips -NVPTX -PowerPC -RISCV -Sparc -SystemZ -WebAssembly -XCore" >> /etc/portage/profile/package.use.force

	# run emaint binhost --fix to ensure Packages file is complete
	# echo "PKGDIR=$DST" >> /etc/portage/make.conf
	# emaint binhost --fix
	# sed -i '$ d' /etc/portage/make.conf

	# disable lto since it uses too much RAM
	mkdir -p /etc/portage/package.use
	echo "*/* lto" >> /etc/portage/package.use/no_lto

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
