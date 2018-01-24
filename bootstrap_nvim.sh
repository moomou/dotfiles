#!/bin/bash

# install vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

pyenv install 3.4.4
pyenv virtualenv 3.4.4 neovim3

pyenv activate neovim3
pip3 install neovim yapf flake8 mypy

ln -s `pyenv which flake8` ~/.local/bin/flake8
ln -s `pyenv which yapf` ~/.local/bin/yapf
ln -s `pyenv which mypy` ~/.local/bin/mypy

echo `which python3`
