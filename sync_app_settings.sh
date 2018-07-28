#!/bin/bash

DIR_PREFIX="$(dirname $0)"
# load all the helper fns
source "$DIR_PREFIX/lib.sh"

# sync spectacle app
symlink "$DIR_PREFIX/extra/osx_spectacle.json" "/Users/$USER/Library/Application Support/Spectacle/Shortcuts.json"

