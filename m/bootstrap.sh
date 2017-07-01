#!/bin/sh

FNAME=m_venv3
M_VENV=/usr/local/bin/$FNAME

PY3=`which python3`
if [ ! -d "$M_VENV" ]; then
    (cd /usr/local/bin && python3 -m venv $FNAME)
fi

$M_VENV/bin/pip install -r pip-requirements.txt

rm -f /usr/local/bin/m
ln -s `pwd`/m /usr/local/bin/m

echo "Setup complete"
