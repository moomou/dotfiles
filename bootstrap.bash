#!/bin/bash

echo "You should have Vim (+ruby) and git installed."

function symlink {
    curDir=${PWD}
    echo Setting up $1

    yes | rm -r ~/${2-$1} 2> /dev/null

    # src -> dest
    ln -s $curDir/$1 ~/${2-$1}
}

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
symlink ".gitencrypt"

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
