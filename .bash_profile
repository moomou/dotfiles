## Shortcut for commands
if [ "$(uname)" == "Darwin" ]; then
    alias ls='gls -X --color --group-directories-first'
fi

alias vi='nvim'
alias vim='nvim'

#alias ctags='/usr/local/bin/ctags'

## Quick folder jmp
alias dev='cd ~/dev'
alias cue='cd ~/dev/cueb'
alias study='cd ~/study'
alias sep='yes hr | head -n 20 | bash'
alias vpn='ssh -C2qTnN -D 8080 hack'

alias nw="/Applications/nwjs.app/Contents/MacOS/nwjs"
alias sep="yes hr | head -n 30 | bash"
alias proxy='ssh -C2qTnN -D 9991 dev'

# Tmux shortcuts
alias tl="tmux list-session"
alias tk="tmux kill-session -t"
alias ta="tmux attach-session -t"
alias ts="tmux new-session -s"

## git alias
alias g="git"
alias gshort="git rev-parse --short"
# if rev-parse is non empty string (obtained via `xargs`), then cd to top level dir
alias groot='[[ ! -z `echo "$(git rev-parse --show-cdup)" | xargs` ]] && cd $(git rev-parse --show-cdup)'
alias gmendq='(groot; sleep 0 && git add . && git ci --amend --no-edit)'
alias gmend='(groot; sleep 0 && git add . && git ci --amend)'
alias gpo='rebase && git push origin'
alias rebase='git pull --rebase origin master && git sub update --init --jobs 4'

alias arcit='gmendq && arc diff'

# Folder jmp
alias box='cd ~/authbox/'
alias fry='cd ~/authbox/ops/chef'
alias gogo='cd ~/authbox/go/src/smyte.com/'
alias cpp='cd ~/authbox/cpp'
alias admin='cd ~/authbox/authbox-api/lib/frontend/admin'
alias api='cd ~/authbox/authbox-api'
alias apps='cd ~/authbox/apps'
alias dev='cd ~/dev'
alias kami='cd ~/authbox/.customer-submodules'
alias sops='cd ~/smyte-ops/'
alias pylib='cd ~/authbox/pylib'
alias sdkpy='cd ~/authbox/sdk/python/smyte-utils/src'
alias gke='sops && cd gke-primary'

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

   #
   local failure='（￣へ￣）'
   #
   local success='(￣▽￣)ノ'

   if [[ "$last_status" != '0' ]]; then
       last_status="$(Color 2)$failure$reset"
   else
       last_status="$(Color 1)$success$reset"
   fi

   # Save and reload the history after each command finishes
   history -a; history -c; history -r;
}

export GOPATH=/home/paul/authbox/go
export MATLAB_HOME='/Applications/MATLAB_R2014a.app'
export ELASTIC_HOME='/Applications/elasticsearch-1.5.2'

# These are required for Caffe
export PYTHONPATH=~/dev/_opensrc/caffe/python:$PYTHONPATH
export CUDA_PATH=/Developer/NVIDIA/CUDA-7.0/bin
export DYLD_LIBRARY_PATH=/Developer/NVIDIA/CUDA-7.0/lib:$DYLD_LIBRARY_PATH

export EXTRA_BIN_DIR=~/.extraBin
export PATH="/usr/local/sbin:$PATH:$CUDA_PATH:$GOPATH/bin:$ELASTIC_HOME/bin:$MATLAB_HOME/bin:$EXTRA_BIN_DIR"
export PATH="/home/paul/.local/bin:$PATH"

# Source the original
source ~/.bashrc
# [[ -s "/Users/moomou/.gvm/scripts/gvm" ]] && source "/Users/moomou/.gvm/scripts/gvm"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, don't overwrite it

# setup Ruby version
rvm use 2.1.2 > /dev/null 2>&1

# Prompt
source ~/.git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWCOLORHINTS=1
export PS1=$PS1'$(__git_ps1 "\[\e[0;32m\](%s) \[\e[0m\]")\n$ '
export PROMPT_COMMAND='echo -n $(BashPrompt)'

export KUBECONFIG=/home/paul/.smyte/gke/kubeconfig kubectl

# box
