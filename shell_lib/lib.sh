function symlink() {
    curDir=${PWD}
    echo Setting up $1

    yes | rm -r ~/${2-$1} 2>/dev/null

    # src -> dest
    ln -s $curDir/$1 ~/${2-$1}
}

# iterm2 specific escape codes
function tab-color() {
    echo -ne "\033]6;1;bg;red;brightness;$1\a"
    echo -ne "\033]6;1;bg;green;brightness;$2\a"
    echo -ne "\033]6;1;bg;blue;brightness;$3\a"
}
function tab-reset() {
    echo -ne "\033]6;1;bg;*;default\a"
}
function cssh() {
    if [[ -n "$ITERM_SESSION_ID" ]]; then
        trap "tab-reset" INT EXIT
        if [[ "$*" =~ "production|ec2-.*compute-1" ]]; then
            tab-color 255 0 0
        else
            tab-color 0 255 0
        fi
    fi
    ssh $*
    tab-reset
}
