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

    # gd_path is an abs path
    gd_path=$(dot_gd_path)
    gd_dir=$(dirname $gd_path)
    key="$1"

    if [ $# -eq 0 ]; then
        cat "$gd_path"
        return
    elif [ $# -eq 2 ]; then
        dst_abs_path=$(realpath "$2")
        rm_prefix="$gd_dir/"
        dst_relative_path="${dst_abs_path#$rm_prefix}"
        entry="$key=$dst_relative_path"
        echo $entry >> $gd_path
        echo Saved $entry
        return
    fi

    while IFS='=' read -ra key_value; do
        if [ "${key_value[0]}" = "$key" ]; then
            cd $gd_dir/${key_value[1]}
            return 0
        fi
    done <<<"$(cat $gd_path)"

    echo "$key not found"
    return 1
}
