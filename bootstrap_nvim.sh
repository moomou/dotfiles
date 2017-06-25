#!/bin/bash

pyenv install 3.4.4
pyenv virtualenv 3.4.4 neovim3

pyenv activate neovim3
pip install neovim yapf flake8

ln -s `pyenv which flake8` ~/.local/bin/flake8
ln -s `pyenv which yapf` ~/.local/bin/yapf

echo `which python3`
