#!/bin/bash

export DISPLAY=:0

# Check if X server is running by testing for lock file
if [ ! -e /tmp/.X0-lock ]; then
    echo "X server not running. Starting X on :0..."

    # Start X server in background
    sudo X :0 & disown

    # Wait for X to initialize by testing nvidia-settings access
    for i in {1..15}; do
        sleep 1
        if nvidia-settings -q gpus &>/dev/null; then
            echo "X server is now running."
            break
        fi
    done

    if ! nvidia-settings -q gpus &>/dev/null; then
        echo "Failed to start X server or access NVIDIA settings. Exiting."
        exit 1
    fi
else
    echo "X server already running on :0"
fi

# Get GPU model
GPU_MODEL=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -n 1)
echo "Detected GPU: $GPU_MODEL"

# Set power limit based on model
if [[ "$GPU_MODEL" == *"5090"* ]]; then
    echo "Setting power limit to 450w"
    sudo nvidia-smi -pl 450
elif [[ "$GPU_MODEL" == *"3090"* ]]; then
    echo "Setting power limit to 300W"
    sudo nvidia-smi -pl 300
else
    echo "Unknown GPU model: $GPU_MODEL. Skipping power limit adjustment."
fi

# Enable manual fan control and set fan speed
echo "Setting fan speed to 95%"
nvidia-settings -a "[gpu:0]/GPUFanControlState=1"
nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=95"
