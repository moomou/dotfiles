#!/bin/bash -xe

ROLE="${1:-box}"
TMP_DIR=$(mktemp -d)
cp -r . $TMP_DIR

cd $TMP_DIR
bash ./run_chef_role.sh' "$ROLE"
