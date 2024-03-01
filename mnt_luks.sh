#!/bin/sh

DEV=/dev/sda1
MNT=hdd

cryptsetup luksOpen "$DEV" "$MNT"
mount "/dev/mapper/$MNT" "/media/$MNT"
