#!/bin/bash

# build web assets via webpack

pushd ~/dev/cueb/web

npm run prod-client

rsync -az dist/prod/* dev:/var/app/ohsloth/dist/

popd
