#!/bin/bash

DOT_GD=".gd"

function groot() {
    git rev-parse --show-toplevel
}

function is_std_git_repo() {
    $(git rev-parse --is-inside-work-tree 2>/dev/null)
}

function dot_gd_path() {
    cur_dir=$(pwd)
    GROOT=$(groot)

    while [ "$cur_dir" != "$GROOT" ]; do
        if [ -e "$cur_dir/$DOT_GD" ]; then
            echo "$cur_dir/$DOT_GD"
            return
        fi
        cur_dir=$(dirname "$cur_dir")
    done

    if [ -e "$cur_dir/$DOT_GD" ]; then
        echo "$cur_dir/$DOT_GD"
    fi
}

function gd() {
    # check if
    if ! is_std_git_repo; then
        echo "Only works in non-bare git repo"
        exit 1
    fi

    dot_gd_content=$(cat $(dot_gd_path))

    IFS='='
    key="$1"
    for path_alias in "$dot_gd_content"; do
        #Read the split words into an array based on comma delimiter
        read -a key_value <<<"$path_alias"
        if [ "${key_value[0]}" = "$key" ]; then
            cd ${key_value[1]}
            return 0
        fi
    done

    echo "$key not found"
    return 1
}
