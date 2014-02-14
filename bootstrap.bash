#!/bin/bash -x

function symlink {
    curDir=${PWD}
    echo Setting up $1

    echo Deleting...
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

if [ "$(uname)" == "Darwin" ]; then
    echo This is a Mac
    brew install mvim
else
    echo You rock 
    sudo apt-get install vim-nox
fi

# Setup vundle
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
vim +BundleInstall +qall
