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
    sudo apt-get update -qq
    sudo apt-get install -y gcc g++ gfortran libcairo-dev libreadline-dev libxt-dev libjpeg-dev libicu-dev libssl-dev libcurl4-openssl-dev subversion git automake make libtool libtiff-dev libpcre2-dev liblzma-dev libbz2-dev gettext rsync curl openssh-client texinfo texlive texlive-fonts-extra
fi

if [ "$ACTION" = build ]; then
    mkdir -p "$OBJ"
    cd "$OBJ"
    echo == Running configure ...
    "$SRC/configure" --enable-R-shlib

    echo == Retrieve SVN revision ...
    ## We have to retrieve SVN info from our .meta.json file
    echo -n "Revision: " && sed -n 's/.*"svnrev": *//p' "$SRC/.meta.json" | sed 's:,.*::' > SVN-REVISION
    echo -n "Last Changed Date: " && sed -n 's/.*"lastdate": *"//p' "$SRC/.meta.json" | sed 's:T.*::' >> SVN-REVISION
    cat SVN-REVISION

    ## Create a fake svn which just outputs that file
    cp -p SVN-REVISION "$HOME/SVN-REVISION"
    mkdir "$HOME/bin"
    echo 'cat ~/SVN-REVISION' > "$HOME/bin/svn"
    chmod a+x "$HOME/bin/svn"
    export PATH="$HOME/bin:$PATH"

    echo == Build ===
    ## Now we can build properly
    make -j4
fi

if [ "$ACTION" = check ]; then
    cd "$OBJ"
    make check
fi
