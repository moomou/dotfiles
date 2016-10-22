#!/bin/bash
ssh slothaws << EOF
    # home dir
    pushd /home/ubuntu

    # Download chub
    if [ -d "chub" ]; then
        git clone git@gitlab.com:moomou/chub.git
    fi

    # Deploy
    pushd chub

    gunzip -c cueb.api.gz | docker load
    gunzip -c cueb.web.gz | docker load

    docker stop cueb.api || true
    docker stop cueb.web || true

    docker run -d -e "NODE_ENV=production" -e "API=localhost:3000" --net=host --name cueb.api
    sleep 5
    docker run -d -e "NODE_ENV=production" -e "API=http://localhost:3000" --net=host --name cueb.web
    sleep 5

    curl localhost:3000/__ping
    curl localhost:5000/__ping
EOF
