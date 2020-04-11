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
    sudo apt-get install -y gcc g++ gfortran libcairo-dev libreadline-dev libxt-dev libjpeg-dev libicu-dev libssl-dev libcurl4-openssl-dev subversion git automake make libtool libtiff-dev libpcre2-dev liblzma-dev libbzip2-dev gettext rsync curl openssh-client texlive texlive-fonts-extra
fi

if [ "$ACTION" = build ]; then
    mkdir -p "$OBJ"
    cd "$OBJ"
    "$SRC/configure" --enable-R-shlib
    make -j4
fi

if [ "$ACTION" = check ]; then
    cd "$OBJ"
    make check
fi
