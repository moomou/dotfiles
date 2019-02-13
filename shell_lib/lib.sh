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
    mkdir -p ~/bin
    symlink $1 $1 ~/bin
}
