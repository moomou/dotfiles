# connect to your server
alias bx='gcloud compute --project ppymou ssh mini -- "/usr/bin/ssh -i ~/moomoutu_rsa moomou@localhost -p 2222"'
alias ctags='/usr/local/bin/ctags'
alias vlc='/Applications/VLC.app/Contents/MacOS/VLC'

# git alias
alias gshort="git rev-parse --short"
# if rev-parse is non empty string (obtained via `xargs`), then cd to top level dir
alias groot='cd $(git rev-parse --show-toplevel)'
alias grootdir='git rev-parse --show-toplevel'
alias gmendq='(groot; sleep 0 && git add . && git ci --amend --no-edit)'
alias gmend='(groot; sleep 0 && git add . && git ci --amend)'
#alias rebase='git pull --rebase origin master && git sub update --init --jobs 4'
alias gpo='rebase && git push origin'
alias gnames='git log --name-status'
alias gnap='git ci -am "checkpoint" && gpo'

## quick folder jmp
alias dev='cd ~/dev'
alias study='cd ~/study'
alias sep='yes hr | head -n 20 | bash'
alias vpnw='ssh -C2qTnN -D 8081 vpn -C'

# tmux shortcuts
alias tl="tmux list-session"
alias tk="tmux kill-session -t"
alias ta="tmux attach-session -t"
alias ts="tmux new-session -s"

# background port-forward
# local to remote
alias lpf='ssh -fNTM local_moomoutu -L'
# remote to local
alias rpf='ssh -fNTM local_moomoutu -R'

# use neovim if installed
if hash nvim 2>/dev/null; then
    alias vi='nvim'
    alias vim='nvim'
fi

# osx alias
if [ "$(uname)" == "Darwin" ]; then
    alias ls='gls -X --color=auto --group-directories-first'
    alias shred='gshred'
    alias canary="/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary --remote-debugging-port=9222"
fi

alias rg='rg -S'
