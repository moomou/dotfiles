#!/bin/bash

echo "You should have Vim (+ruby) and git installed."

function symlink {
    curDir=${PWD}
    echo Setting up $1

    yes | rm -r ~/$1 2> /dev/null

    # src -> dest
    ln -s $curDir/$1 ~/$1 
}

# Override .vimrc & .vim folder
symlink ".vim"
symlink ".vimrc"

# Override .ssh config
symlink ".ssh/config"

# Link .gitconfig
symlink ".gitconfig"

# Link .sbtconfig
symlink ".sbtconfig"

# Link bash_*
symlink ".bash_profile"
symlink ".sbtconfig"

symlink ".oh-my-zsh"

# Using .bashrc as custom config on different machines
if [ "$BASHRC" = "1" ]; then
    symlink ".bashrc"
fi

# Setup vundle
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
echo "Now run: vi +BundleInstall +qall"
