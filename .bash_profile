# Shortcut for commands
if [ "$(uname)" == "Darwin" ]; then
    alias vi='mvim -v'
    alias vim='mvim -v'
fi

alias ctags='/usr/local/bin/ctags'

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

   # 囧
   local failure='\xe5\x9b\xa7'
   # ❤
   local success='\xE2\x9D\xA4\x20'

   if [[ "$last_status" != '0' ]]; then
       last_status="$(Color 2)$failure$reset"
   else
       last_status="$(Color 1)$success$reset"
   fi

   echo -n -e $last_status;
}

export PROMPT_COMMAND='echo -n $(BashPrompt)'

# Source the original
source ~/.bashrc

# Source autoenv
source /usr/local/opt/autoenv/activate.sh
