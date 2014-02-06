
# Setting up git complete
curl https://raw.github.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

gitCompleteCmd='if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi'
