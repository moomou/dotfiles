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
symlink ".tmux.conf" ".tmux.conf"

# Link .gitconfig
symlink ".gitconfig"
symlink ".git-prompt.sh"

# Link bash_*
symlink ".bash_profile"

# Link other utils
symlink ".agignore"
symlink ".eslintrc"
symlink ".gitignore"
symlink ".jshintrc"
symlink ".sbtconfig"

# Using .bashrc as custom config on different machines
if [ "$BASHRC" = "1" ]; then
    symlink ".bashrc"
fi

# Setup vundle
# git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
# echo "Now run: vi +BundleInstall +qall"

# Setting up git
git config --global core.excludesfile ~/.gitignore_global
