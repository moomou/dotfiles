#!/bin/bash

# turn off wifi power saving
sudo iw dev wlp8s0 set power_save off
# configure power mode in gpu
[[ $(command -v nvidia-smi) ]] && sudo nvidia-smi -pl 300 &>/dev/null
