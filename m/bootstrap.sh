#!/bin/sh

M_VENV=/usr/local/bin/m_venv

if [ ! -d "$M_VENV" ]; then
    (cd /usr/local/bin && virtualenv m_venv)
fi

/usr/local/bin/m_venv/bin/pip install -r pip-requirements.txt

rm -f /usr/local/bin/m
ln -s `pwd`/m /usr/local/bin/m

echo "Setup complete"
