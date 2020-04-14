#!/bin/bash

# bail out on any error
set -e

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
    sudo apt-get install -q -y gcc g++ gfortran libcairo-dev libreadline-dev libxt-dev libjpeg-dev libicu-dev libssl-dev libcurl4-openssl-dev subversion git automake make libtool libtiff-dev libpcre2-dev liblzma-dev libbz2-dev gettext rsync curl openssh-client texinfo texlive unzip

    ## install inconsolata, required for vignettes
    ## texlive-fonts-extra has it, but is HUGE so let's fetch it directly from CTAN
    (cd /tmp
     curl -LO http://mirrors.ctan.org/install/fonts/inconsolata.tds.zip
     mkdir zi4
     cd zi4
     unzip -q ../inconsolata.tds.zip
     sudo chown -Rh 0:0 .
     sudo rsync -a ./ /usr/share/texmf/
     sudo rm -rf /tmp/zi4
    )
    ## update TeX cache and font map
    sudo -i texhash
    sudo -i updmap-sys --enable Map=zi4.map
fi

if [ "$ACTION" = build ]; then
    cd "$OBJ"
    echo == Running configure ...
    "$SRC/configure" --enable-R-shlib

    echo == Retrieve SVN revision ...
    ## We have to retrieve SVN info from our .meta.json file
    sed -n 's/.*"svnrev": *//p' "$SRC/.meta.json" | sed 's:,.*::' | sed 's/^/Revision: /' > SVN-REVISION
    sed -n 's/.*"lastdate": *"//p' "$SRC/.meta.json" | sed 's:T.*::' | sed 's/^/Last Changed Date: /' >> SVN-REVISION
    cat SVN-REVISION

    ## Create a fake svn which just outputs that file
    cp -p SVN-REVISION "$BASE/SVN-REVISION"
    echo "cat $BASE/SVN-REVISION" > "$LOCALBIN/svn"
    chmod a+x "$LOCALBIN/svn"

    ## pretend we're not using git or else we'd  have to fake git as well..
    if [ -e "$SRC/.git" ]; then mv "$SRC/.git" "$SRC/.git.bak"; fi

    echo == Build ===
    ## Now we can build properly
    make -j4

    ## restore .git
    if [ -e "$SRC/.git.bak" ]; then mv "$SRC/.git.bak" "$SRC/.git"; fi
fi

if [ "$ACTION" = check ]; then
    cd "$OBJ"
    ## we don't want to die anymore - we want to handle failures
    ## to report diagnostics
    set +e
    ok=true
    make check || ok=false
    if [ "$ok" != true ]; then
	echo "**  make check FAILED"
	echo ''
	for i in `find "$OBJ" -name \*fail`; do
	    echo ''
	    echo "**  FAILED test: $i"
	    echo ''
	    cat $i
	    echo ''
	done
	exit 1
    fi
    echo ''
    echo '-- DONE --'
    echo ''
fi
