#!/bin/bash

# load all the helper fns
source "$(dirname $0)/shell_lib/lib.sh"

# Random script for different os
symlink_bin "gogo"
symlink_bin "godep"

if [ $(uname) = "Darwin" ]; then
fi
