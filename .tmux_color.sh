#!/bin/bash
# ~/.tmux_color.sh
VAL=$(hostname | md5sum | cut -c1-2)
DEC=$((16#$VAL))
echo "color$(( (DEC % 200) + 16 ))"
