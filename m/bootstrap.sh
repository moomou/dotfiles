#!/bin/bash

set -euo pipefail

# required for audiolab
# sudo apt-get install -y libsndfile1 libsndfile1-dev
DST=~/.local/bin

FNAME=m_venv3
M_VENV=$DST/$FNAME

if [ ! -d "$M_VENV" ]; then
    (cd $DST && python3 -m venv $FNAME)
fi

# idk why this complains about numpy
$M_VENV/bin/python3 -m pip install --no-cache-dir numpy wheel
$M_VENV/bin/python3 -m pip install -r pip-requirements.txt

rm -f $DST/m
ln -s $(pwd)/m $DST/m

echo "m setup complete"
