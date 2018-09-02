#!/bin/bash

# import constant
source ./shell_lib/const.sh

# run some os specific setup
if [ $(uname) = "Darwin" ]; then
    ./shell_lib/bootstrap_mac.sh
else
    ./shell_lib/bootstrap_linux.sh
fi

# install pyenv
curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $DEFAULT_PYTHON_VERSION
pyenv global $DEFAULT_PYTHON_VERSION

source ~/.bash_profile

mkdir -p ~/bin

# Setting up m
echo "Setting up m"
(cd ./m && sudo ./bootstrap.sh)
