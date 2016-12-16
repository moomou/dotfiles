## Shortcut for commands
if [ "$(uname)" == "Darwin" ]; then
    alias ls='gls -X --color --group-directories-first'
    alias gvi='~/.govim.sh'
    alias gvim='~/.govim.sh'
    alias vi='mvim -v'
    alias vim='mvim -v'
    alias imgcat='~/imgcat'

    export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_102.jdk/Contents/Home
    export MATLAB_HOME='/Applications/MATLAB_R2014a.app'
    export ELASTIC_HOME='/Applications/elasticsearch-1.5.2'

    # set power status on osx
    if [[ $(pmset -g ps | head -1) =~ "AC Power" ]]; then
       export ACPOWER=1
    else
       export ACPOWER=0
    fi
fi
if hash nvim 2>/dev/null && [ "$(uname)" == "Linux" ]; then
    alias vi='nvim'
    alias vim='nvim'
fi

# connect to your server
alias bx='ssh -t dev ssh -i /root/.ssh/keys/personal_rsa box'
alias ctags='/usr/local/bin/ctags'

## github alias
alias g="git"
alias gshort="git rev-parse --short"
# if rev-parse is non empty string (obtained via `xargs`), then cd to top level dir
alias groot='[[ ! -z `echo "$(git rev-parse --show-cdup)" | xargs` ]] && cd $(git rev-parse --show-cdup)'
alias gmendq='(groot; sleep 0 && git add . && git ci --amend --no-edit)'
alias gmend='(groot; sleep 0 && git add . && git ci --amend)'
alias rebase='git pull --rebase origin master && git sub update --init --jobs 4'
alias gpo='rebase && git push origin'
alias gnames='git log --name-status'

ginit() {
    git init;
    lan=`echo $1 | python -c "print raw_input().capitalize()"`;
    wget -q https://raw.githubusercontent.com/github/gitignore/master/${lan}.gitignore -O .gitignore;
    git add .;
    git ci -am 'init with .gitignore';
}

## Quick folder jmp
alias dev='cd ~/dev'
alias study='cd ~/study'
alias sep='yes hr | head -n 20 | bash'
alias vpnw='ssh -C2qTnN -D 8081 vpn'

# tmux shortcuts
alias tl="tmux list-session"
alias tk="tmux kill-session -t"
alias ta="tmux attach-session -t"
alias ts="tmux new-session -s"

## Global ag ignore
alias ag='ag --path-to-agignore=~/.agignore'

## Make vim the default
export EDITOR=vim

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
   local last_status=$?
   local reset=$(ResetColor)

   local failure=' (ಠ_ಠ) '
   local success=' ヽ(・∀・)ﾉ '

   if [[ "$last_status" != '0' ]]; then
       last_status="$(Color 2)$failure$reset"
   else
       last_status="$(Color 1)$success$reset"
   fi

   echo -n -e $last_status;
}

# Some generic env var
export GOPATH=$HOME/go
export CUDA_PATH==/usr/local/cuda-8.0
export PYENV_PATH=/home/moomou/.pyenv/
export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export PATH="/usr/local/sbin:$PYENV_PATH/bin:$PATH:$CUDA_PATH/bin:$GOPATH/bin:$ELASTIC_HOME/bin:$MATLAB_HOME/bin:/Users/moomou/bin"

# Source the original
source ~/.bashrc

# Source files if exists
# TODO: refactor into common func
# source /usr/local/opt/autoenv/activate.sh
[[ -s "/Users/moomou/.gvm/scripts/gvm" ]] && source "/Users/moomou/.gvm/scripts/gvm"
[[ -s "~/.cuebenv/activate.sh" ]] && source ". ~/.cuebenv/activate.sh"

source ~/.git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWCOLORHINTS=1
export PS1=$PS1'$(__git_ps1 "\[\e[0;32m\](%s) \[\e[0m\]")\n$ '
export PROMPT_COMMAND='echo -n $(BashPrompt)'

# pyenv dark magic
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# jmp to dev
dev
