#!/bin/bash

if [ ! -f ./secret/foo.txt ]; then
    echo "Decrypting..."
    blackbox_postdeploy >/dev/null 2>&1
fi

for f in `find ./secret -type f | grep -v gpg`
do
    echo "Processed $f file..."
    chmod 0600 $f
done
