#!/bin/bash

# bail out on any error
set -e

ACTION="$1"
OS=`uname -s`

fold_start() {
  echo -e "travis_fold:start:$1\033[33;1m$2\033[0m"
}

fold_end() {
  echo -e "\ntravis_fold:end:$1\r"
}

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
    fold_start sysdeps.apt 'Install packages via apt-get'
    ## for Ubuntu/Debian
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -q -y gcc g++ gfortran libcairo-dev libreadline-dev libxt-dev libjpeg-dev libicu-dev libssl-dev libcurl4-openssl-dev subversion git automake make libtool libtiff-dev libpcre2-dev liblzma-dev libbz2-dev gettext rsync curl openssh-client texinfo texlive unzip tzdata locale
    fold_end sysdeps.apt

    ## generate locale
    sudo -i locale-gen en_US.UTF-8

    fold_start sysdeps.tex 'Install TeX packages/fonts'
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
    fold_end sysdeps.tex
fi

if [ "$ACTION" = config ]; then
    cd "$OBJ"
    fold_start R.config "Running configure ..."
    set -x
    "$SRC/configure" --enable-R-shlib
    set +x
    fold_end R.config
fi

if [ "$ACTION" = build ]; then
    cd "$OBJ"
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

    ## Now we can build properly
    fold_start R.build "Building R ..."
    make -j4
    fold_end R.build

    ## restore .git
    if [ -e "$SRC/.git.bak" ]; then mv "$SRC/.git.bak" "$SRC/.git"; fi
fi

if [ "$ACTION" = check ]; then
    cd "$OBJ"
    ## we don't want to die anymore - we want to handle failures
    ## to report diagnostics
    set +e
    ok=true
    fold_start R.check "Running make check ..."
    make check || ok=false
    fold_end R.check
    if [ "$ok" != true ]; then
	echo -e "${ANSI_RED} **  make check FAILED ** ${ANSI_RESET}"
	echo ''
	for i in `find "$OBJ" -name \*fail`; do
	    echo ''
	    fid="ft.`basename $i`"
	    fold_start "$fid" "Failed test: $i"
	    cat $i
	    fold_end "$fid"
	    echo ''
	done

	fold_start R.info "R sessionInfo"
	bin/R -e 'sessionInfo()'
	gcc --version
	gfortran --version
	fold_end R.info

	fold_start R.env "Environment variables"
	bin/R CMD /bin/bash -c set
	fold_end R.env

	fold_start R.config.log "R config.log"
	cat config.log
	fold_end R.config.log

	exit 1
    fi
    echo ''
    echo -e "${ANSI_GREEN}-- DONE --${ANSI_RESET}"
    echo ''
fi
