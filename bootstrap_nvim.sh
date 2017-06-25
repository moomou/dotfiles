#!/bin/bash

pyenv install 3.4.4
pyenv virtualenv 3.4.4 neovim3
pyenv activate neovim3
pip install neovim
pyenv which python  # Note the path
pip install yapf

echo `which python3`
pyenv deactivate neovim3
