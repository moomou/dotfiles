set +o history

# <PROFILING START>
#PS4='+ $(gdate "+%s.%N")\011 '
#exec 3>&2 2>/tmp/bashstart.$$.log
#set -x
# </PROFILING START>

complete -d cd

## shortcut for commands
if [[ $OSTYPE == darwin* ]]; then
    export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_102.jdk/Contents/Home
    # set power status on osx
    if [[ $(/usr/bin/pmset -g ps) == *"AC Power"* ]]; then
        export ACPOWER=1
    else
        export ACPOWER=0
    fi
fi

if [ -f ~/.prompt_prefix ]; then
    PROMPT_PREFIX=$(< ~/.prompt_prefix)
else
    PROMPT_PREFIX=''
fi

## Make vim the default
export EDITOR=vim

## Git auto complete
if [[ $- == *i* ]] && [ -f ~/.git-completion.bash ]; then
    . ~/.git-completion.bash
fi

# Some generic env var
export GOPATH=$HOME/go
export PYENV_PATH=$HOME/.pyenv
export PROTOC_BIN=/usr/local/protoc/bin
# export CUDA_PATH=/usr/local/cuda-12.1
# export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64:$LD_LIBRARY_PATH
export CUDA_PATH=/usr/local/cuda
export LD_LIBRARY_PATH="/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

_configure_path() {
    local entry old_ifs
    local new_path=
    local -a entries existing

    entries=(
        "$HOME/.antigravity/antigravity/bin"
        "${ASDF_DATA_DIR:-$HOME/.asdf}/shims"
        "${ASDF_DIR:-$HOME/.asdf}/bin"
        "$HOME/.poetry/bin"
        "$HOME/.bun/bin"
        "$HOME/.cargo/bin"
        "$HOME/google-cloud-sdk/bin"
        /usr/local/go/bin
        /opt/homebrew/bin
        "$HOME/Library/Python/3.11/bin"
        "$HOME/.fz/bin"
        "$HOME/.local/bin"
        /usr/local/sbin
        "$PYENV_PATH/bin"
        "$CUDA_PATH/bin"
        "$GOPATH/bin"
    )
    [[ -n ${MATLAB_HOME:-} ]] && entries+=("$MATLAB_HOME/bin")
    entries+=("$HOME/bin" "$PROTOC_BIN")

    old_ifs=$IFS
    IFS=:
    read -ra existing <<< "$PATH"
    IFS=$old_ifs
    entries+=("${existing[@]}")

    for entry in "${entries[@]}"; do
        [[ -n $entry && $entry != '~/'* ]] || continue
        case ":$new_path:" in
            *":$entry:"*) ;;
            *) new_path="${new_path:+$new_path:}$entry" ;;
        esac
    done

    PATH=$new_path
}

_configure_path
export PATH
# skip git lfs by default
export GIT_LFS_SKIP_SMUDGE=1

# Source the original
source ~/.bashrc 2>/dev/null

# source files if exists
# [[ -s "~/.cuebenv/activate.sh" ]] && source ". ~/.cuebenv/activate.sh"

# Check whether Git LFS filters are configured at a repository root.
is_git_lfs_directory() {
  if [ -d .git ] && git config --get-regexp '^filter\.lfs\.' >/dev/null 2>&1; then
    return 0  # It's a Git LFS directory
  else
    return 1  # It's not a Git LFS directory
  fi
}

# Configure the prompt only for interactive shells.
if [[ $- == *i* ]]; then
    if is_git_lfs_directory; then
        export GIT_PROMPT_ONLY_IN_REPO=1
    else
        export GIT_PROMPT_ONLY_IN_REPO=0
        export GIT_PS1_SHOWDIRTYSTATE=1
        export GIT_PS1_SHOWSTASHSTATE=1
        export GIT_PS1_SHOWCOLORHINTS=1
        if [ -f ~/.git-prompt.sh ]; then
            source ~/.git-prompt.sh
            export PS1=$PS1'$(__git_ps1 "\[\e[0;32m\](%s) \[\e[0m\]")\n$ '
        fi
        PROMPT_COMMAND=BashPrompt
    fi
fi

#export GIT_PS1_SHOWDIRTYSTATE=1
#export GIT_PS1_SHOWSTASHSTATE=1
#export GIT_PS1_SHOWCOLORHINTS=1

#export PS1=$PS1'$(__git_ps1 "\[\e[0;32m\](%s) \[\e[0m\]")\n$ '
#export PROMPT_COMMAND='last_command_exit_code="${_}#${?}" && BashPrompt'

# fuck homebrew & mac
export HOMEBREW_NO_AUTO_UPDATE=1
export BASH_SILENCE_DEPRECATION_WARNING=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export APPLE_SSH_ADD_BEHAVIOR=macos

# make ls on linux simliar to osx
export LC_COLLATE=C
export CLOUDSDK_PYTHON=python3

[[ $- == *i* ]] && test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# The next line updates PATH for the Google Cloud SDK.
if [ -f "~/google-cloud-sdk/path.bash.inc" ]; then source "~/google-cloud-sdk/path.bash.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "~/google-cloud-sdk/completion.bash.inc" ]; then source "~/google-cloud-sdk/completion.bash.inc"; fi

[[ $- == *i* && -n $ITERM_SESSION_ID ]] && tab-color

[[ -f "$HOME/.asdf/asdf.sh" ]] && ASDF_FORCE_PREPEND=no source "$HOME/.asdf/asdf.sh"
unset -f _configure_path


# <PROFILING STOP>
#set +x
#exec 2>&3 3>&-
# </PROFILING STOP>

# This line needs to be LAST
# to prevent .bash_profile in history
# including COMMENTS
set -o history -o histexpand
