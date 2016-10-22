#!/bin/bash

role=$1

# This runs as root on the server
chef_binary=chef-solo

# Are we on a vanilla system?
# if ! command -v $chef_binary >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    # Upgrade headlessly (this is only safe-ish on vanilla systems)
    apt-get update &&
    apt-get -o Dpkg::Options::="--force-confnew" \
        --force-yes -fuy dist-upgrade &&
    # Install Ruby, Chef, and its dep
    apt-get install -y \
        ruby2.3 \
        ruby2.3-dev \
        make \
        libgmp-dev \
        gcc \
        &&

    sudo gem2.3 install --no-rdoc --no-ri chef berkshelf
# fi

# install dep cookbooks
sudo berks vendor ./vendor

# run chef
sudo "$chef_binary" -c solo.rb -j "./roles/${role}.json"
