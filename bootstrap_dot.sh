#!/bin/bash

# load all the helper fns
source "$(dirname $0)/shell_lib/lib.sh"

echo "You should have neovim (+ruby) and git installed."

# make sure nvim dir exists
mkdir -p ~/.config/nvim
symlink ".vimrc" ".config/nvim/init.vim"

# OpenCode
mkdir -p ~/.config/opencode
symlink "opencode.json" ".config/opencode/opencode.json"

if [ -x ~/.bun/bin/opencode.real ]; then
    symlink "opencode_wrapper.sh" ".bun/bin/opencode"
elif [ -x ~/.bun/bin/opencode ]; then
    mv ~/.bun/bin/opencode ~/.bun/bin/opencode.real
    symlink "opencode_wrapper.sh" ".bun/bin/opencode"
elif command -v opencode >/dev/null 2>&1 && [ -d ~/.asdf/plugins/nodejs/shims ]; then
    symlink "opencode_wrapper.sh" ".asdf/plugins/nodejs/shims/opencode"
fi

# Override .vimrc & .vim folder
symlink ".vim"
symlink ".vimrc"
symlink ".vimrc" ".nvimrc"
symlink ".vim" ".nvim"

# tmux
symlink ".tmux.conf"
symlink ".tmux_color.sh"

# Setup .ssh
symlink ".ssh_rc" ".ssh/rc"
# symlink ".ssh/config"
# symlink ".ssh/cert"
# symlink ".ssh/key"

# Link .git settings
symlink ".gitconfig"
symlink ".git-prompt.sh"

# Link bash_*
symlink ".bash_profile"
symlink ".bash_aliases"
symlink ".bash_fns"

# Link other utils
symlink ".agignore"
symlink ".eslintrc"
symlink ".gitignore_global"
symlink ".gitatributes_global"
symlink ".jshintrc"
symlink ".sbtconfig"
symlink ".prettierrc"
symlink "gd" ".gd"

# Random script for different os
if [ $(uname) = "Darwin" ]; then
    symlink "vimGoWrapper.sh" ".govim.sh"
fi

symlink ".bashrc"

# Setting up git
git config --global core.excludesfile ~/.gitignore_global
