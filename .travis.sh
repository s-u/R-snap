#!/bin/bash

# bail out on any error
set -ev

ACTION="$1"
OS=`uname -s`

echo ''
echo " == Action: $ACTION =="
echo ''
uname -a

OBJ="$HOME/R-build"
SRC="`pwd`"

if [ "$ACTION" = sysdeps ]; then
    ## for Ubuntu/Debian
    ## NOTE: texlive-fonts-extra is HUGE so we avoid it if we can ...
    sudo apt-get update -qq
    sudo apt-get install -y gcc g++ gfortran libcairo-dev libreadline-dev libxt-dev libjpeg-dev libicu-dev libssl-dev libcurl4-openssl-dev subversion git automake make libtool libtiff-dev libpcre2-dev liblzma-dev libbz2-dev gettext rsync curl openssh-client texinfo texlive
fi

if [ "$ACTION" = build ]; then
    ## we need to fake out configure since we don't use SVN checkouts
    ## so we retrieve the info from our .meta.json file
    echo -n "Revision: " && sed -n 's/.*"svnrev": *//p' .meta.json | sed 's:,.*::' > SVN-REVISION
    echo -n "Last Changed Date: " && sed -n 's/.*"lastdate": *"//p' .meta.json | sed 's:T.*::' >> SVN-REVISION
    ## FIXME: for now we just pretend, but ...
    ## at some point we may just need to create an svn-shim ...
    touch doc/FAQ

    mkdir -p "$OBJ"
    cd "$OBJ"
    "$SRC/configure" --enable-R-shlib
    make -j4
fi

if [ "$ACTION" = check ]; then
    cd "$OBJ"
    make check
fi
