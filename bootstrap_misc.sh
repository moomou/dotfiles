#!/bin/bash

# install pyenv
curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

exec "$SHELL"

# install pyenv virtualenv
$ git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv

# Setting up m
echo Setting up m
(cd ./m && ./bootstrap.sh)
