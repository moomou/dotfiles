## Shortcut for commands
if [ "$(uname)" == "Darwin" ]; then
    alias ls='gls -X --color --group-directories-first'
    alias gvi='~/.govim.sh'
    alias gvim='~/.govim.sh'
    alias vi='mvim -v'
    alias vim='mvim -v'
fi

alias imgcat='~/imgcat'
alias ctags='/usr/local/bin/ctags'

## github alias
# if rev-parse is non empty string (obtained via `xargs`), then cd to top level dir
alias groot='[[ ! -z `echo "$(git rev-parse --show-cdup)" | xargs` ]] && cd $(git rev-parse --show-cdup)'
alias gmend='groot; sleep 0 && git add . && git ci --amend'
alias gmendq='groot; sleep 0 && git add . && git ci --amend --no-edit'
alias rebase='git pull --rebase origin master'
alias gpo='rebase && git push origin'

g_init() {
    git init;
    lan=`echo $1 | python -c "print raw_input().capitalize()"`;
    wget -q https://raw.githubusercontent.com/github/gitignore/master/${lan}.gitignore -O .gitignore;
    git add .;
    git ci -am 'init with .gitignore';
}

alias gnames='git log --name-status'
alias ginit='g_init'

## Quick folder jmp
alias dev='cd ~/dev'
alias cue='cd ~/dev/cueb'
alias study='cd ~/study'
alias sep='yes hr | head -n 20 | bash'
alias vpnw='ssh -C2qTnN -D 8081 vpn'
alias vpndo='ssh -C2qTnN -D 8081 dev'

# Tmux shortcuts
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

export GOPATH=$HOME/go
export MATLAB_HOME='/Applications/MATLAB_R2014a.app'
export ELASTIC_HOME='/Applications/elasticsearch-1.5.2'

# These are required for Caffe
export PYTHONPATH=~/dev/_opensrc/caffe/python:$PYTHONPATH
export CUDA_PATH=/Developer/NVIDIA/CUDA-7.0/bin
export DYLD_LIBRARY_PATH=/Developer/NVIDIA/CUDA-7.0/lib:$DYLD_LIBRARY_PATH
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_102.jdk/Contents/Home

export PATH="/usr/local/sbin:$PATH:$CUDA_PATH:$GOPATH/bin:$ELASTIC_HOME/bin:$MATLAB_HOME/bin:/Users/moomou/bin"

# Source the original
source ~/.bashrc

# Source autoenv
# source /usr/local/opt/autoenv/activate.sh
[[ -s "/Users/moomou/.gvm/scripts/gvm" ]] && source "/Users/moomou/.gvm/scripts/gvm"

if [ -f ~/.cuebenv/activate.sh ]; then
    . ~/.cuebenv/activate.sh
fi

source ~/.git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWCOLORHINTS=1
export PS1=$PS1'$(__git_ps1 "\[\e[0;32m\](%s) \[\e[0m\]")\n$ '
export PROMPT_COMMAND='echo -n $(BashPrompt)'

# Python dark magic
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
