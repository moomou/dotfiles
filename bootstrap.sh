#!/bin/bash

# install pyenv
curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.5.4
pyenv global 3.5.4

so ~/.bash_profile

mkdir -p ~/bin

# Setting up m
echo Setting up m
(cd /usr/local/bin && wget https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy && chmod +x diff-so-fancy)
(cd ./m && sudo ./bootstrap.sh)
