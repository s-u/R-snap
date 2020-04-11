#!/bin/bash

# bail out on any error
#set -ev

ACTION="$1"
OS=`uname -s`

echo ''
echo " == Action: $ACTION =="
echo ''
echo "MY_ENV_VAR=${MY_ENV_VAR}"
echo ''
uname -a

if [ "$ACTION" = sysdeps ]; then
    sudo apt-get install -y gcc g++ gfortran libcairo-dev libreadline-dev libxt-dev libjpeg-dev libicu-dev libssl-dev libcurl4-openssl-dev subversion git automake make libtool libtiff-dev gettext rsync curl openssh-client
fi

if [ "$ACTION" = build ]; then
    echo Build
    pwd

    OBJ="$HOME/build"
    SRC="`pwd`"
    mkdir -p "$OBJ"
    cd "$OBJ"
    "$SRC/configure" --enable-R-shlib
    make -j4
fi

if [ "$ACTION" = check ]; then
    echo Check
    pwd

    OBJ="$HOME/build"
    cd "$OBJ"
    make check
fi
