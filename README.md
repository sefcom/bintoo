# bintoo

This is a binary compilation tool that abuses the gentoo build system to get binaries in gentoo's packages with different compilation options.

```
cat Dockerfile.gbuilder | docker build -t gbuilder -

# compile all packages with -O0 and put them into the ./out-0 directory
cat listing.amd64 | parallel --eta -j12 ./launch.sh 0

# compile all packages with -O1 and put them into the ./out-1 directory
cat listing.amd64 | parallel --eta -j12 ./launch.sh 1

# compile all packages with -O2 and put them into the ./out-2 directory
cat listing.amd64 | parallel --eta -j12 ./launch.sh 2

# compile all packages with -O3 and put them into the ./out-3 directory
cat listing.amd64 | parallel --eta -j12 ./launch.sh 3
```

To regenerate the listing:

```
emerge eix
eix-update
EIX_LIMIT=0 eix | grep "^*" | cut -f2 -d' ' | grep -v "^acct-"
```
