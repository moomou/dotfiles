#!/bin/bash
ssh slothdb << EOF
    echo Deploying...

    # mkdir data dir
    if [ ! -d "/data/elasticsearch" ]; then
        sudo mkdir -p /data/elasticsearch
    fi
    if [ ! -d "/data/redis" ]; then
        sudo mkdir -p /data/redis
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
    docker rm cueb.elasticsearch > /dev/null 2>&1
    docker stop cueb.redis > /dev/null 2>&1
    docker rm cueb.redis > /dev/null 2>&1

    docker run -d --net=bridge \
        -v "/data/redis/":"/data/redis" \
        -p 6379:6379 \
        --name cueb.redis \
        cueb.redis
    sleep 5

    docker run -d --net=bridge \
        -v "/data/elasticsearch":/usr/share/elasticsearch/data \
        -p 9200:9200 \
        --name cueb.elasticsearch \
        cueb.elasticsearch
    sleep 5

    # basic healthcheck
    until redis-cli ping;
    do
        echo waiting for redis...
        sleep 1
    done

    until curl -s -XGET 'http://localhost:9200/_cluster/health?pretty=true' > /dev/null;
    do
        echo waiting for elasticsearch...
        sleep 1
    done

    # Setup elasticsearch
    pushd cueb/api/scripts
    ./es_setup.bash localhost:9200
EOF
