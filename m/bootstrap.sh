#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")

# required for audiolab
# sudo apt-get install -y libsndfile1 libsndfile1-dev
DST=~/.local/bin
FNAME=m_venv3

pushd $DST

uv venv $FNAME
source $FNAME/bin/activate

# idk why this complains about numpy
uv pip install -r $SCRIPT_DIR/pip-requirements.txt

popd

rm -f $DST/m
ln -s $SCRIPT_DIR/m $DST/m

echo "m setup complete"
