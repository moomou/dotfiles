#!/bin/bash

# install pyenv
curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.5.4
pyenv global 3.5.4

# Setting up m
echo Setting up m
(cd ./m && sudo ./bootstrap.sh)
