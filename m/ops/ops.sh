setup_chub() {
    # Download chub
    if [ ! -d "chub" ]; then
        git clone --depth=1 git@gitlab.com:moomou/chub.git
    else
        pushd chub
        git pull origin master
        popd
    fi
}
export -f setup_chub

load_docker_img_from_chub() {
    # Deploy
    pushd chub
    gunzip -c $1 | docker load
    popd
}
export -f load_docker_img_from_chub

stop_docker_container() {
    name=$1
    docker stop $name > /dev/null 2>&1
    docker rm $name > /dev/null 2>&1
}
export -f stop_docker_container;

wait_until() {
    COMMAND=$@

    until `$COMMAND` > /dev/null;
    do
        echo waiting...
        sleep 1
    done
}
export -f wait_until
