function symlink() {
    curDir=${PWD}
    src_fname=$1
    dst_fname=${2-$(basename $1)}

    prefix=${3-~}
    dst_path=$prefix/$dst_fname

    echo "Setting up $src_fname and linking to $dst_path"
    yes | rm -r $dst_path 2>/dev/null

    ln -s $curDir/$src_fname $dst_path
}

function symlink_bin() {
    symlink $1 $1 /usr/local/sbin
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
