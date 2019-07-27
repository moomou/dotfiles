#!/bin/bash -xe

# This script removes the default external NAT of a Gcloud VM using `gcloud`
# and assigns it a new one

VM=$1
ZONE=$2

if ! hash jq 2>/dev/null; then
    echo This script requires "jq" >&2
    exit 1
fi

function get_external_nat() {
    RES=$(gcloud compute instances describe "$1" --zone "$2" --format json | jq .networkInterfaces[0].accessConfigs[0] -c)
    echo "$RES"
}

NAT=$(get_external_nat "$VM" "$ZONE")
# remove
gcloud compute instances delete-access-config "$VM" --zone "$ZONE" --access-config-name "$(echo $NAT | jq -r .name)"

# add
gcloud compute instances add-access-config "$VM" --zone "$ZONE"
NAT=$(get_external_nat "$VM" "$ZONE")

echo $(echo "$NAT" | jq -r .natIP)
