#!/bin/bash

echo Deploying...

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

# Deploy
pushd chub
gunzip -c cueb.api.gz | docker load
gunzip -c cueb.web.gz | docker load
popd

# in /home/ubuntu
docker stop cueb.api > /dev/null 2>&1
docker rm cueb.api > /dev/null 2>&1
docker stop cueb.web > /dev/null 2>&1
docker rm cueb.web > /dev/null 2>&1

docker run -d --net=bridge \
    -e "NODE_ENV=production" \
    -e "ELASTICSEARCH=http://172.31.1.141:9200" \
    -e "REDIS=redis://172.31.1.141:6379" \
    -p 3000:3000 \
    --name cueb.api \
    cueb.api

until curl -s -XGET 'localhost:3000/__ping' > /dev/null;
do
    echo waiting for api...
    sleep 1
done

# TODO: dynamically get docker ip
docker run -d --net=bridge \
    -e "NODE_ENV=production" \
    -e "API=http://172.17.0.1:3000" \
    -e "REDIS=redis://172.31.1.141:6379" \
    -p 5000:5000 \
    --name cueb.web \
    cueb.web

until curl -s -XGET 'localhost:5000/__ping' > /dev/null;
do
    echo waiting for web...
    sleep 1
done
