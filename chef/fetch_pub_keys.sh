#!/bin/bash -xe

wget 'https://gitlab.com/moomou.keys' -O gitlab_keys
wget 'https://github.com/moomou.keys' -O github_keys

cat github_keys >>~/.ssh/authorized_keys
cat gitlab_keys >>~/.ssh/authorized_keys
