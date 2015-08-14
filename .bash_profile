# Shortcut for commands
if [ "$(uname)" == "Darwin" ]; then
    alias vi='mvim -v -w /tmp/output.txt'
    alias vim='mvim -v -w /tmp/output.txt'
    alias ls='gls -X --color --group-directories-first'
fi

alias ctags='/usr/local/bin/ctags'
alias nw="/Applications/nwjs.app/Contents/MacOS/nwjs"

# Quick folder jmp
alias dev='cd ~/dev'
alias study='cd ~/study'

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
export ELASTIC_HOME='/Applications/elasticsearch-1.5.2/'
export PATH="$PATH:$GOPATH/bin:$ELASTIC_HOME/bin"

# Source the original
source ~/.bashrc

# Source autoenv
source /usr/local/opt/autoenv/activate.sh
[[ -s "/Users/moomou/.gvm/scripts/gvm" ]] && source "/Users/moomou/.gvm/scripts/gvm"

if [ -f ~/.cuebenv/activate.sh ]; then
    . ~/.cuebenv/activate.sh
fi
