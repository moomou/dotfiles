#!/bin/bash

while :; do
    STATUS=$(curl -s https://lab.ohsloth.com | awk '{print $1}')

    echo "[$(date)]" $STATUS
    if [ "$STATUS" == "OK" ]; then
        sleep 30
    else
        echo restarting...
        supervisorctl restart spa_tunnel
        sleep 30
    fi
done
