# Shortcut for commands
if [ "$(uname)" == "Darwin" ]; then
    alias vi='mvim -v'
    alias vim='mvim -v'
fi

alias ctags='/usr/local/bin/ctags'

# Quick folder jmp
alias dev='cd ~/dev'
alias course='cd ~/Documents/study'

# Source the original
source ~/.bashrc

# Make vim the default
export EDITOR=vim

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

   if [[ "$last_status" != "0" ]]; then
       last_status="$(Color 8)$failure$reset"
   else
       last_status="$(Color 1)$success$reset"
   fi

   echo -n -e $last_status;
}

export PROMPT_COMMAND='history -a; echo -n $(BashPrompt)'
