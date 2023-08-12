set +o history

# PROFILING START
#PS4='+ $(gdate "+%s.%N")\011 '
#exec 3>&2 2>/tmp/bashstart.$$.log
#set -x
# PROFILING START

complete -d cd

## shortcut for commands
if [ "$(uname)" == "Darwin" ]; then
    export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_102.jdk/Contents/Home
    # set power status on osx
    if [[ $(pmset -g ps | head -1) =~ "AC Power" ]]; then
        export ACPOWER=1
    else
        export ACPOWER=0
    fi
fi

if [ -f ~/.prompt_prefix ]; then
    PROMPT_PREFIX=$(cat ~/.prompt_prefix)
else
    PROMPT_PREFIX=''
fi

## Make vim the default
export EDITOR=nvim

## Bash Completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi
## Git auto complete
if [ -f ~/.git-completion.bash ]; then
    . ~/.git-completion.bash
fi

# Some generic env var
export GOPATH=$HOME/go
export PYENV_PATH=$HOME/.pyenv/
export PROTOC_BIN=/usr/local/protoc/bin
export CUDA_PATH=/usr/local/cuda-11.8
export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH
export H5_BIN=~/dev/_opensrc/hdf5-1.10.1-patch1/hdf5/bin

export PATH="$H5_BIN:/usr/local/sbin:$PYENV_PATH/bin:$CUDA_PATH/bin:$GOPATH/bin:$MATLAB_HOME/bin:~/bin:$PROTOC_BIN:$PATH"
export PATH=~/.local/bin:$PATH
export PATH="~/.fz/bin:$PATH"
export PATH="~/Library/Python/3.11/bin:$PATH"

# Source the original
source ~/.bashrc 2>/dev/null

# source files if exists
# [[ -s "~/.cuebenv/activate.sh" ]] && source ". ~/.cuebenv/activate.sh"

source ~/.git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWCOLORHINTS=1

export PS1=$PS1'$(__git_ps1 "\[\e[0;32m\](%s) \[\e[0m\]")\n$ '
export PROMPT_COMMAND='last_command_exit_code="${_}#${?}" && BashPrompt'

# fuck homebrew & mac
export HOMEBREW_NO_AUTO_UPDATE=1
export BASH_SILENCE_DEPRECATION_WARNING=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export APPLE_SSH_ADD_BEHAVIOR=macos

# make ls on linux simliar to osx
export LC_COLLATE=C
export CLOUDSDK_PYTHON=python3.9

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/moomou/google-cloud-sdk/path.bash.inc' ]; then source '/Users/moomou/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/moomou/google-cloud-sdk/completion.bash.inc' ]; then source '/Users/moomou/google-cloud-sdk/completion.bash.inc'; fi

tab-color

export PATH="$HOME/.poetry/bin:$PATH"
. "$HOME/.cargo/env"

# PROFILING STOP
#set +x
#exec 2>&3 3>&-
# PROFILING STOP

. "$HOME/.cargo/env"

# This line needs to be LAST
# to prevent .bash_profile in history
# including COMMENTS
set -o history -o histexpand

