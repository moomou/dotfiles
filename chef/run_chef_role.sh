#!/bin/bash

RUBY_VERSION=ruby2.4
CHEF_BINARY=chef-solo

role=$1

# Are we on a vanilla system?
if ! command -v $CHEF_BINARY >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive

    # Install Ruby, Chef, and its dep
    if ! $(apt-cache search $RUBY_VERSION | grep -q $RUBY_VERSION); then
        apt-add-repository ppa:brightbox/ruby-ng -y
    fi

    apt-get update &&
        apt-get install -y \
            $RUBY_VERSION \
            $RUBY_VERSION-dev \
            make \
            libgmp-dev \
            gcc &&
        sudo gem2.4 install --no-rdoc --no-ri chef berkshelf
fi

echo Installing deps...
sudo berks vendor ./vendor

echo Starting chef run...
sudo "$CHEF_BINARY" -c "$(pwd)/solo.rb" -j "$(pwd)/roles/${role}.json"
