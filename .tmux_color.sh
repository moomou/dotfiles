#!/bin/bash
# ~/.tmux_color.sh
VAL=$(hostname | md5sum | cut -c1-2)
DEC=$((16#$VAL))
COLOR="color$(( (DEC % 200) + 16 ))"

# Tell tmux to set the style
tmux set -g status-style "bg=$COLOR,fg=black"
