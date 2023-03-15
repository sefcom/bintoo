FROM gentoo/stage3

# sync and install crossdev
run emerge --sync
run emerge sys-devel/crossdev

# setup overlay for crossdev
run mkdir -p /var/db/repos/crossdev/{profiles,metadata}
run echo 'crossdev' > /var/db/repos/crossdev/profiles/repo_name
run echo 'masters = gentoo' > /var/db/repos/crossdev/metadata/layout.conf
run chown -R portage:portage /var/db/repos/crossdev

# create and update crossdev repo.conf
run mkdir -p /etc/portage/repos.conf
run touch /etc/portage/repos.conf/crossdev.conf
run echo $'[crossdev]\nlocation = /var/db/repos/crossdev\npriority = 10\nmasters = gentoo\nsync-type = rsync\nsync-uri = rsync://rsync.us.gentoo.org/gentoo-portage/\nauto-sync = yes' > /etc/portage/repos.conf/crossdev.conf

# install toolchain
run crossdev --stable --target aarch64-linux-gnu
#aarch64-linux-gnu

# copy stage3 files
copy aarch64/* /usr/aarch64-linux-gnu/
workdir /usr/aarch64-linux-gnu/
run tar xvJpf stage3-arm64-*.tar.xz --xattrs-include='*.*' --numeric-owner
run rm stage3-arm64-*.tar.xz*

# fix symlink
run rm /usr/aarch64-linux-gnu/etc/portage/make.profile
run ln -s /var/db/repos/gentoo/profiles/default/linux/arm64/17.0/desktop /usr/aarch64-linux-gnu/etc/portage/make.profile

# set root to sysroot
ENV ROOT=/usr/aarch64-linux-gnu/

# sync toolchain
run aarch64-linux-gnu-emerge --sync
run aarch64-linux-gnu-emerge --oneshot sys-apps/portage
run echo $'>=x11-libs/cairo-1.17.6 X\n>=media-libs/libglvnd-1.6.0 X' > /etc/portage/package.use/custom 
run aarch64-linux-gnu-emerge --update --deep --with-bdeps=y --newuse @world --exclude python:3.10.10 --exclude x11-libs/gtk+
run aarch64-linux-gnu-emerge eix


# copy qemu static
copy qemu-aarch64-static /usr/aarch64-linux-gnu/

# for eix
run mkdir -p /usr/aarch64-linux-gnu/var/cache/eix/
run touch /usr/aarch64-linux-gnu/var/cache/eix/portage.eix
run chown -R  portage:portage /usr/aarch64-linux-gnu/var/cache/eix

# to make crossdev visible to eix
run echo $'PORTDIR="/var/db/repos/crossdev"' >> /usr/aarch64-linux-gnu/etc/portage/make.conf

# eix does not generate the list so tried copying categories but it still does not build the database for crossdev
copy categories /usr/aarch64-linux-gnu/var/db/repos/crossdev/profiles/categories

# saves things to /usr/aarch64-linux-gnu/usr/bin instead of /usr/bin for amd64
run echo $'DISTDIR="/usr/aarch64-linux-gnu/var/cache/distfiles"\nPKGDIR="/usr/aarch64-linux-gnu/var/cache/binpkgs"' >> /usr/aarch64-linux-gnu/etc/portage/make.conf

# copy build_aarch64.sh
copy build_aarch64.sh /usr/aarch64-linux-gnu/

 
# setup Qemu
#run echo  -e '>=dev-libs/glib-2.74.4 static-libs\n>=sys-libs/zlib-1.2.13-r1 static-libs\n>=sys-apps/attr-2.5.1-r2 static-libs\n>=dev-libs/libpcre2-10.42-r1 static-libs' >> /etc/portage/package.use/custom
#run QEMU_USER_TARGETS="aarch64" QEMU_SOFTMMU_TARGETS="aarch64" USE="static-user static-libs" emerge --buildpkg --oneshot qemu
#run emerge --usepkgonly --oneshot --nodeps qemu


#run eix-update
#run EIX_LIMIT=0 eix | grep "^*" | cut -f2 -d' ' | grep "^acct-" | USE=gitea xargs aarch64-linux-gnu-emerge
#ENTRYPOINT ["tail", "-f", "/dev/null"]

