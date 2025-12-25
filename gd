#!/bin/bash

DOT_GD=".gd"

function dot_gd_path() {
    cur_dir=${1:-$(pwd)}
    groot=$(git rev-parse --show-toplevel)

    while [ "$cur_dir" != "$groot" ]; do
        if [ -e "$cur_dir/$DOT_GD" ]; then
            break
        fi
        cur_dir=$(dirname "$cur_dir")
    done

    if [ -e "$cur_dir/$DOT_GD" ]; then
        echo "$cur_dir/$DOT_GD"
    fi
}

function gd() {
    if ! $(git rev-parse --is-inside-work-tree 2>/dev/null); then
        echo "Only works in non-bare git repo"
        return 1
    fi

    groot=$(git rev-parse --show-toplevel)
    # gd_path is an abs path
    gd_path=$(dot_gd_path)

    if [ -z "$gd_path" ]; then
        echo no "$DOT_GD" found
        return 1
    fi

    gd_dir=$(dirname $gd_path)
    key="$1"

    if [ $# -eq 0 ]; then
        # cat out gd content when no args specified
        # ex `gd`
        cat "$gd_path"

        # TODO: cat all gds recursively upwards
        return
    elif [ $# -eq 2 ]; then
        # save mapping when 2 args specified
        # ex `gd a b`
        dst_abs_path=$(realpath "$2")
        rm_prefix="$gd_dir/"
        dst_relative_path="${dst_abs_path#$rm_prefix}"
        entry="$key=$dst_relative_path"
        
        # Check if key already exists and replace it
        if grep -q "^$key=" "$gd_path"; then
            # Replace existing entry
            temp_file=$(mktemp)
            while IFS='=' read -ra key_value; do
                if [ "${key_value[0]}" = "$key" ]; then
                    echo "$entry" >> "$temp_file"
                else
                    echo "${key_value[0]}=${key_value[1]}" >> "$temp_file"
                fi
            done <"$gd_path"
            mv "$temp_file" "$gd_path"
            echo Replaced $entry
        else
            # Add new entry
            echo "$entry" >> "$gd_path"
            echo Saved $entry
        fi
        return
    fi

    while true; do
        while IFS='=' read -ra key_value; do
            if [ "${key_value[0]}" = "$key" ]; then
                cd $gd_dir/${key_value[1]}
                return 0
            fi
        done <<<"$(cat $gd_path)"

        gd_dir=$(dirname $gd_path)
        if [[ "$gd_dir" == "$groot" ]]; then
            echo "$key not found"
            return 1
        fi

        gd_parent_dir=$(dirname $gd_dir)
        next_gd_path=$(dot_gd_path "$gd_parent_dir")

        if [[ "$gd_path" == "$next_gd_path" ]]; then
            echo "$key not found"
            return 1
        fi

        gd_path="$next_gd_path"
        gd_dir=$(dirname $gd_path)
    done
}
