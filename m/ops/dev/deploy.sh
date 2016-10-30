#!/bin/bash -xe
echo Deploying services

pushd /root

setup_chub

load_docker_img_from_chub svc.linguist
load_docker_img_from_chub grpc.gateway

stop_docker_container grpc.gateway
stop_docker_container svc.linguist

echo Starting...

docker run -d --net=bridge \
    -p 50051:50051 \
    --name svc.linguist \
    svc.linguist

docker run -d --net=bridge \
    -p 8080:8080 \
    --name grpc.gateway \
    grpc.gateway

popd
