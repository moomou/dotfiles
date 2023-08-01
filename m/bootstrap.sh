#!/bin/bash

set -euo pipefail

# required for audiolab
# sudo apt-get install -y libsndfile1 libsndfile1-dev

FNAME=m_venv3
M_VENV=/usr/local/bin/$FNAME

if [ ! -d "$M_VENV" ]; then
    (cd /usr/local/bin && python3 -m venv $FNAME)
fi

# idk why this complains about numpy
$M_VENV/bin/pip install --no-cache-dir numpy wheel
$M_VENV/bin/pip install -r pip-requirements.txt

rm -f /usr/local/bin/m
ln -s $(pwd)/m /usr/local/bin/m

echo "m setup complete"
