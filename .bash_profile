# Shortcut for commands
if [ "$(uname)" == "Darwin" ]; then
    alias ls='gls -X --color --group-directories-first'
    alias vi='mvim -v -w /tmp/output.txt'
    alias vim='mvim -v -w /tmp/output.txt'
fi

alias ctags='/usr/local/bin/ctags'

# Quick folder jmp
alias dev='cd ~/dev'
alias cue='cd ~/dev/cueb'
alias study='cd ~/study'
alias sep='yes hr | head -n 20 | bash'
alias vpn='ssh -C2qTnN -D 8080 hack'
alias tl='tmux list-session'
alias ta='tmux attach-session -t'

# Global ag ignore
alias ag='ag --path-to-agignore=~/.agignore'

# Make vim the default
export EDITOR=vim

# Bash Completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# Git auto complete
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

   echo -n -e $last_status;
}

export PROMPT_COMMAND='echo -n $(BashPrompt)'

export GOPATH=$HOME/go
export MATLAB_HOME='/Applications/MATLAB_R2014a.app'
export ELASTIC_HOME='/Applications/elasticsearch-1.5.2'

# These are required for Caffe
export PYTHONPATH=~/dev/_opensrc/caffe/python:$PYTHONPATH
export CUDA_PATH=/Developer/NVIDIA/CUDA-7.0/bin
export DYLD_LIBRARY_PATH=/Developer/NVIDIA/CUDA-7.0/lib:$DYLD_LIBRARY_PATH

export PATH="/usr/local/sbin:$PATH:$CUDA_PATH:$GOPATH/bin:$ELASTIC_HOME/bin:$MATLAB_HOME/bin"

# Source the original
source ~/.bashrc

# Source autoenv
source /usr/local/opt/autoenv/activate.sh
[[ -s "/Users/moomou/.gvm/scripts/gvm" ]] && source "/Users/moomou/.gvm/scripts/gvm"

if [ -f ~/.cuebenv/activate.sh ]; then
    . ~/.cuebenv/activate.sh
fi
