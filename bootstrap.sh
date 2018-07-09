#!/bin/bash

# assume debian from https://github.com/pyenv/pyenv/wiki/Common-build-problems#requirements
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev

# install pyenv
curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.5.4
pyenv global 3.5.4

source ~/.bash_profile

mkdir -p ~/bin

# Setting up m
echo Setting up m
(cd ./m && sudo ./bootstrap.sh)
