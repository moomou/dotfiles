#!/bin/bash

host=$1

tar cj . | ssh -o 'StrictHostKeyChecking no' "$host" '
sudo rm -rf ~/ops &&
mkdir ~/ops &&
cd ~/ops &&
tar xj &&
sudo bash -c' "echo Running... && source ./ops.sh && $host/deploy.sh"
