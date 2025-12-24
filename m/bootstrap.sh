#!/bin/bash

set -euo pipefail

# required for audiolab
# sudo apt-get install -y libsndfile1 libsndfile1-dev
DST=~/.local/bin

if ! command -v uv &> /dev/null; then
    echo "uv is not installed. Installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

rm -f $DST/m
ln -s $(pwd)/m $DST/m
chmod +x $DST/m

echo "m setup complete"
