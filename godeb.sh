#!/bin/bash -el

cdir=$PWD
while [ "$cdir" != "/" ]; do
    if [ -e "$cdir/.gopath" ]; then
        if [[ $GOPATH != *"$cdir"* ]]; then
            export GOPATH=$cdir:$GOPATH
        fi
        break
    fi
    cdir=$(dirname "$cdir")
done
echo $GOPATH
exec dep "$@"
