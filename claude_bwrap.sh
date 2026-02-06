#!/bin/bash

PROJECT_DIR=$(pwd)
ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
CLAUD_DIR="${CLAUD_DIR:-$HOME/.claude}"
USER_ID=$(id -u)
GROUP_ID=$(id -g)
USERNAME="$(whoami)"

bwrap \
  --ro-bind /usr /usr \
  --ro-bind /bin /bin \
  --ro-bind /lib /lib \
  --ro-bind /lib64 /lib64 \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp \
  --tmpfs /home \
  --share-net \
  --ro-bind /etc/resolv.conf /etc/resolv.conf \
  --ro-bind /etc/ssl /etc/ssl \
  --ro-bind /etc/pki /etc/pki \
  --ro-bind /etc/hosts /etc/hosts \
  --ro-bind-try /etc/ca-certificates /etc/ca-certificates \
  --setenv HOME "/home/$USERNAME" \
  --setenv PATH "$PATH" \
  --setenv USER "$USERNAME" \
  --dir "/home/$USERNAME" \
  --dir "/home/$USERNAME/.claude" \
  --tmpfs "/home/$USERNAME/.claude/debug" \
  --tmpfs "/home/$USERNAME/.claude/sessions" \
  --ro-bind "$ASDF_DATA_DIR" "/home/$USERNAME/.asdf" \
  --ro-bind "$CLAUD_DIR" "/home/$USERNAME/.claude_ro" \
  --ro-bind-try "$HOME/.tool-versions" "/home/$USERNAME/.tool-versions" \
  --ro-bind-try "$HOME/.gitconfig" "/home/$USERNAME/.gitconfig" \
  --bind "$PROJECT_DIR" "/home/$USERNAME/project" \
  --chdir "/home/$USERNAME/project" \
  --unshare-user --uid 1000 --gid 1000 \
  -- /bin/bash -c "
    [ -f \"$HOME/.claude_ro/settings.json\" ] && cp \"$HOME/.claude_ro/settings.json\" \"/home/$USERNAME/.claude/settings.json\"
    unset command_not_found_handle
    exec /home/$USERNAME/.asdf/shims/claude \"\$@\"
  " -- --permission-mode plan --dangerously-skip-permissions "$@"
