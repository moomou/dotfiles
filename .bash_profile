set -o history -o histexpand
complete -d cd

## shortcut for commands
if [ "$(uname)" == "Darwin" ]; then
    export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_102.jdk/Contents/Home
    export MATLAB_HOME='/Applications/MATLAB_R2014a.app'
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

ginit() {
    git init
    lan=$(echo $1 | python -c "print raw_input().capitalize()")
    wget -q https://raw.githubusercontent.com/github/gitignore/master/${lan}.gitignore -O .gitignore
    git add .
    git ci -am 'init with .gitignore'
}

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

# Custom Prompt
function Color() {
    echo "$(tput setaf $1)"
}
function ResetColor() {
    echo "$(tput sgr0)"
}
function BashPrompt() {
    local reset=$(ResetColor)
    local last_command=$(echo $last_command_exit_code | awk -F "#" '{print $1}')
    local last_status=$(echo $last_command_exit_code | awk -F "#" '{print $2}')

    local failure='(ಠ_ಠ) '
    local success='ヽ(・∀・)ﾉ '

    last_status="$(Color 1)$success$reset[$PROMPT_PREFIX]."
    echo -n -e $last_status
}

# Some generic env var
export GOPATH=$HOME/go
export PYENV_PATH=$HOME/.pyenv/
export PROTOC_BIN=/usr/local/protoc/bin
export CUDA_PATH=/usr/local/cuda-8.0
export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export H5_BIN=~/dev/_opensrc/hdf5-1.10.0-patch1/hdf5/bin
export PATH="$H5_BIN:/usr/local/sbin:$PYENV_PATH/bin:$CUDA_PATH/bin:$GOPATH/bin:$MATLAB_HOME/bin:~/bin:$PROTOC_BIN:$PATH"
export PATH=~/.local/bin:$PATH
export PATH="~/.fz/bin:$PATH"

# Source the original
source ~/.bashrc 2>/dev/null

# source files if exists
[[ -s "~/.cuebenv/activate.sh" ]] && source ". ~/.cuebenv/activate.sh"

source ~/.git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWCOLORHINTS=1

export PS1=$PS1'$(__git_ps1 "\[\e[0;32m\](%s) \[\e[0m\]")\n$ '
export PROMPT_COMMAND='last_command_exit_code="${_}#${?}" && BashPrompt'

# fuck homebrew
export HOMEBREW_NO_AUTO_UPDATE=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# make ls on linux simliar to osx
export LC_COLLATE=C

# pyenv dark magic
function initpyenv() {
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
}

initpyenv

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

export PATH="$HOME/.cargo/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/moomou/google-cloud-sdk/path.bash.inc' ]; then source '/Users/moomou/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/moomou/google-cloud-sdk/completion.bash.inc' ]; then source '/Users/moomou/google-cloud-sdk/completion.bash.inc'; fi
