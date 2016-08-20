#!/bin/bash -el

cdir=$PWD
while [ "$cdir" != "/" ]; do
    if [ -e "$cdir/.gopath" ]; then
        if [[ $GOPATH != *"$cdir"* ]]; then
            export GOPATH=$GOPATH:$cdir
        fi
        break
    fi
    cdir=$(dirname "$cdir")
done

exec mvim -v -w /tmp/output.txt "$@"
