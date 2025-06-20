#!/bin/sh

MAPPER_NAME="$1"
MOUNT_POINT="/mnt/secure_mount"

sudo umount "$MOUNT_POINT"
sudo cryptsetup luksClose "$MAPPER_NAME"
echo "Disk unmounted and closed."
