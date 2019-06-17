#!/bin/bash -xe

# Usage: ./bootstrap_remote.sh [host] [role]

host="${1}"
role="${2:-box}"

# The host key might change when we instantiate a new VM, so
# we remove (-R) the old host key from known_hosts
ssh-keygen -R "${host#*@}" 2>/dev/null

echo Running role $role...
echo

tar cj . | ssh -o 'StrictHostKeyChecking no' "$host" '
cd $(mktemp -d) &&
    tar xj &&
    sudo bash run_chef_role.sh ' "$role"
