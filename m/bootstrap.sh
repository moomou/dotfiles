#!/bin/sh

# required for audiolab
sudo apt-get install -y libsndfile1 libsndfile1-dev

FNAME=m_venv3
M_VENV=/usr/local/bin/$FNAME

if [ ! -d "$M_VENV" ]; then
    (cd /usr/local/bin && python3 -m venv $FNAME)
fi

# idk why this complains about numpy
$M_VENV/bin/pip install numpy
$M_VENV/bin/pip install -r pip-requirements.txt

rm -f /usr/local/bin/m
ln -s $(pwd)/m /usr/local/bin/m

echo "m setup complete"
