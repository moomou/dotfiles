#!/bin/bash
ssh slothdb << EOF
    sudo su

    echo Deploying...

    # mkdir data dir
    if [ ! -d "/data/elasticsearch" ]; then
        mkdir -p /data/elasticsearch
    fi

    # home dir
    pushd /home/ubuntu

    # Download chub
    if [ ! -d "chub" ]; then
        git clone git@gitlab.com:moomou/chub.git
    else
        pushd chub
        git pull origin master
        popd
    fi
    if [ ! -d "cueb" ]; then
        git clone git@gitlab.com:moomou/cueb.git
    else
        pushd cueb
        git pull origin master
        popd
    fi

    # Deploy
    pushd chub
    gunzip -c cueb.elasticsearch.gz | docker load
    gunzip -c cueb.redis.gz | docker load
    popd

    # in /home/ubuntu
    docker stop cueb.elasticsearch > /dev/null 2>&1
    docker stop cueb.redis > /dev/null 2>&1

    docker run -d --net=host --name cueb.redis cueb.redis
    sleep 5
    docker run -d --net=host -v "/data/elasticsearch":/usr/share/elasticsearch/data --name cueb.elasticsearch cueb.elasticsearch
    sleep 5

    # basic healthcheck
    redis-cli info memory
    curl -XGET 'http://localhost:9200/_cluster/health?pretty=true'

    # Setup elasticsearch
    pushd cueb/api/scripts
    ./es_setup.bash localhost:9200
EOF
