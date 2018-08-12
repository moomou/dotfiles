#!/bin/bash

# load all the helper fns
source "$(dirname $0)/lib.sh"

echo "You should have neovim (+ruby) and git installed."

symlink ".yapf" ".config/yapf/style"

# make sure nvim dir exists
mkdir -p ~/.config/nvim
symlink ".vimrc" ".config/nvim/init.vim"

# Override .vimrc & .vim folder
symlink ".vim"
symlink ".vimrc"
symlink ".vimrc" ".nvimrc"
symlink ".vim" ".nvim"

# tmux
symlink ".tmux.conf"

# Setup .ssh
symlink ".ssh/config"
symlink ".ssh/cert"
symlink ".ssh/key"

# Link .git settings
symlink ".gitconfig"
symlink ".git-prompt.sh"

# Link bash_*
symlink ".bash_profile"
symlink ".bash_aliases"

# Link other utils
symlink ".agignore"
symlink ".eslintrc"
symlink ".gitignore_global"
symlink ".jshintrc"
symlink ".sbtconfig"
symlink ".prettierrc"

# Random script for different os
if [ `uname` = "Darwin" ]; then
    symlink "vimGoWrapper.sh" ".govim.sh"
    symlink "gogo" "gogo"
    symlink "godep" "godep"
    symlink "./extraBin/imgcat" "imgcat"
fi

# Using .bashrc as custom config on different machines
if [ "$BASHRC" = "1" ]; then
    symlink ".bashrc"
fi

# Setting up git
git config --global core.excludesfile ~/.gitignore_global