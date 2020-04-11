#!/bin/bash

# bail out on any error
set -ev

ACTION="$1"
OS=`uname -s`

echo ''
echo " == Action: $ACTION =="
echo ''
uname -a

BASE="$HOME/R-build"
OBJ="$BASE/obj"
LOCALBIN="$BASE/bin"
SRC="`pwd`"

if [ ! -d "$OBJ" ]; then
    mkdir -p "$OBJ"
fi
if [ ! -d "$LOCALBIN" ]; then
    mkdir -p "$LOCALBIN"
fi
export PATH="$LOCALBIN:$PATH"

if [ "$ACTION" = sysdeps ]; then
    ## for Ubuntu/Debian
    sudo apt-get update -qq
    sudo apt-get install -q -y gcc g++ gfortran libcairo-dev libreadline-dev libxt-dev libjpeg-dev libicu-dev libssl-dev libcurl4-openssl-dev subversion git automake make libtool libtiff-dev libpcre2-dev liblzma-dev libbz2-dev gettext rsync curl openssh-client texinfo texlive texlive-fonts-extra
fi

if [ "$ACTION" = build ]; then
    cd "$OBJ"
    echo == Running configure ...
    "$SRC/configure" --enable-R-shlib

    echo == Retrieve SVN revision ...
    ## We have to retrieve SVN info from our .meta.json file
    echo -n "Revision: " && sed -n 's/.*"svnrev": *//p' "$SRC/.meta.json" | sed 's:,.*::' > SVN-REVISION
    echo -n "Last Changed Date: " && sed -n 's/.*"lastdate": *"//p' "$SRC/.meta.json" | sed 's:T.*::' >> SVN-REVISION
    cat SVN-REVISION

    ## Create a fake svn which just outputs that file
    cp -p SVN-REVISION "$BASE/SVN-REVISION"
    echo "cat $BASE/SVN-REVISION" > "$LOCALBIN/svn"
    chmod a+x "$LOCALBIN/svn"

    echo == Build ===
    ## Now we can build properly
    make -j4
fi

if [ "$ACTION" = check ]; then
    cd "$OBJ"
    make check
fi
