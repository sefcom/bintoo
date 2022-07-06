FROM gentoo/stage3:amd64
run mkdir -p /etc/portage/repos.conf/
copy gentoo.conf /etc/portage/repos.conf/gentoo.conf
run emerge --sync
run emerge --oneshot sys-apps/portage
run emerge -v1 dev-perl/Locale-gettext sys-apps/help2man
run emerge --update --deep --with-bdeps=y --newuse @world --exclude python:3.10
copy listing.amd64 /
run cat listing.amd64 | grep "^acct" | USE=gitea xargs emerge
COPY hooks/hook_execve.so /
#copy build.sh /
