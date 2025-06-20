#!/bin/bash

# Detect wireless interface
for iface in /sys/class/net/*; do
    iface_name=$(basename "$iface")
    if [ -d "/sys/class/net/$iface_name/wireless" ]; then
        IFACE="$iface_name"
        echo "Wi-Fi interface detected: $IFACE"
        break
    fi
done

# Exit if not found
if [ -z "$IFACE" ]; then
    echo "❌ No Wi-Fi interface found."
    exit 1
fi

# turn off wifi power saving
iw dev "$IFACE" set power_save off

# Clear existing rules
tc qdisc del dev "$IFACE" root 2>/dev/null

# Root HTB qdisc
#tc qdisc add dev "$IFACE" root handle 1: htb default 20

## Classes: High (10) for prioritized traffic, Default (20) for others
#tc class add dev "$IFACE" parent 1: classid 1:10 htb rate 1mbit ceil 20mbit prio 0
#tc class add dev "$IFACE" parent 1: classid 1:20 htb rate 512kbit ceil 20mbit prio 1

## Prioritize SSH (port 22)
#tc filter add dev "$IFACE" protocol ip parent 1:0 prio 1 u32 \
    #match ip dport 22 0xffff flowid 1:10
#tc filter add dev "$IFACE" protocol ip parent 1:0 prio 1 u32 \
    #match ip sport 22 0xffff flowid 1:10

## Prioritize jupyter (port 8888)
#tc filter add dev "$IFACE" protocol ip parent 1:0 prio 1 u32 \
    #match ip dport 8888 0xffff flowid 1:10
#tc filter add dev "$IFACE" protocol ip parent 1:0 prio 1 u32 \
    #match ip sport 8888 0xffff flowid 1:10
