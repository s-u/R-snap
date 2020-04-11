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
    ## install some tex pkgs by hand
    sudo -i tlmgr init-usertree
    sudo -i tlmgr update --self
    sudo -i tlmgr install titling framed inconsolata
fi

if [ "$ACTION" = build ]; then
    mkdir -p "$OBJ"
    cd "$OBJ"
    "$SRC/configure" --enable-R-shlib

    ## We have to retrieve SVN info from our .meta.json file
    echo -n "Revision: " && sed -n 's/.*"svnrev": *//p' .meta.json | sed 's:,.*::' > SVN-REVISION
    echo -n "Last Changed Date: " && sed -n 's/.*"lastdate": *"//p' .meta.json | sed 's:T.*::' >> SVN-REVISION
    ## the way R checks is to find docs, so building them will do it
    ## note that this is may be fragile if the check Makefile:svnonly
    ## changes
    (cd doc/manual && make -j4 front-matter html-non-svn)

    ## Now we can build properly
    make -j4
fi

if [ "$ACTION" = check ]; then
    cd "$OBJ"
    make check
fi
