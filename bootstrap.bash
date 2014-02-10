function symlink() {
    echo Setting up $1
    if [ -d ~/$1 ]; then
        rm -r ~/$1
    fi
    ln -s ./$1 ~/$1
}

# Override .vimrc & .vim folder
symlink('.vim')
ln -s ./.vimrc ~/.vimrc

# Override .ssh config
symlink('.ssh/config')

# Link .gitconfig
symlink('.gitconfig')

# Link .sbtconfig
symlink('.sbtconfig')

# Link bash_*
symlink('.bash_profile')
symlink('.sbtconfig')
