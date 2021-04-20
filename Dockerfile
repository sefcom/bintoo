FROM gentoo/stage3:amd64
run emerge --sync
run emerge --update --deep --with-bdeps=y --newuse @world
copy listing.amd64 /
#run cat listing.amd64 | grep "^acct" | USE=gitea xargs emerge
copy build.sh /
