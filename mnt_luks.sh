#!/bin/sh

IMAGE="$1"
MAPPER_NAME="secure_disk"
MOUNT_POINT="/mnt/secure_mount"

sudo cryptsetup luksOpen "$IMAGE" "$MAPPER_NAME"
sudo mkdir -p "$MOUNT_POINT"
sudo mount "/dev/mapper/$MAPPER_NAME" "$MOUNT_POINT"
echo "Disk mounted at $MOUNT_POINT"

