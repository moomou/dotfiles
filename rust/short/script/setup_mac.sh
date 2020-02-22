#!/bin/bash

networksetup -listallnetworkservices | tail -n +2 |
    while read net; do
        if echo $net | grep -iq "wi-fi"; then
            #sudo networksetup -setsearchdomains $net go.mou.dev
            echo "Setup $net searchdomain to go.mou.dev"
        fi
    done
