FROM gentoo/stage3:amd64
run mkdir -p /etc/portage/repos.conf/
copy gentoo.conf /etc/portage/repos.conf/gentoo.conf
run emerge --sync
run emerge --oneshot sys-apps/portage
#run emerge -v1 dev-perl/Locale-gettext sys-apps/help2man
run emerge --update --deep --with-bdeps=y --newuse @world --exclude python:3.10

# install all acct- packages
run emerge eix
run eix-update
run echo -e ">=acct-group/resin-0\n=acct-group/shellinaboxd-0-r1\n=acct-user/shellinaboxd-0-r1"  >> /etc/portage/package.unmask
run EIX_LIMIT=0 eix | grep "^*" | cut -f2 -d' ' | grep "^acct-" | USE=gitea xargs emerge

COPY hooks/hook_execve.so /
#copy build.sh /
