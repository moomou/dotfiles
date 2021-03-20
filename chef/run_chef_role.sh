#!/bin/bash -xe
set -euo pipefail

[ "${EUID:-$(id -u)}" -eq 0 ] || $(echo "Requires sudo" && exit 1)

RUBY_VERSION=2.6
CHEF_VERSION=14.13.11
BERKSHELF_VERISON=7.0.7

RUBY=ruby$RUBY_VERSION
CHEF_BINARY=chef-solo

role=$1

# Are we on a vanilla system?
if ! command -v $CHEF_BINARY >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive

    # Install Ruby, Chef, and its dep
    if ! $(apt-cache search $RUBY | grep -q $RUBY); then
        apt-add-repository ppa:brightbox/ruby-ng -y
    fi

    apt-get update &&
        apt-get install -y \
            $RUBY \
            $RUBY-dev \
            make \
            libgmp-dev \
            gcc &&
        gem$RUBY_VERSION install --no-doc chef:$CHEF_VERSION berkshelf:$BERKSHELF_VERISON
fi

echo Installing deps...
berks vendor ./vendor

echo Starting chef run...
"$CHEF_BINARY" -c "$(pwd)/solo.rb" -j "$(pwd)/roles/${role}.json"
