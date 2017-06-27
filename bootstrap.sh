#!/bin/bash

echo "You should have Vim (+ruby) and git installed."

function symlink {
    curDir=${PWD}
    echo Setting up $1

    yes | rm -r ~/${2-$1} 2> /dev/null

    # src -> dest
    ln -s $curDir/$1 ~/${2-$1}
}

symlink ".yapf" ".config/yapf/style"

# make sure nvim dir exists
mkdir -p ~/.config/nvim
symlink ".vimrc" ".config/nvim/init.vim"

# Override .vimrc & .vim folder
symlink ".vim"
symlink ".vimrc"
symlink ".vimrc" ".nvimrc"
symlink ".vim" ".nvim"

# Tmux
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

# Link other utils
symlink ".agignore"
symlink ".eslintrc"
symlink ".gitignore_global"
symlink ".jshintrc"
symlink ".sbtconfig"

# Random script for different os
if [ `uname` = "Darwin" ]; then
    symlink "vimGoWrapper.sh" ".govim.sh"
    symlink "gogo.sh" "gogo.sh"
    symlink "./extraBin/imgcat" "imgcat"
fi

# Using .bashrc as custom config on different machines
if [ "$BASHRC" = "1" ]; then
    symlink ".bashrc"
fi

# Setting up git
git config --global core.excludesfile ~/.gitignore_global

# Setting up m
echo Setting up m
(cd ./m && ./bootstrap.sh)
