#!/bin/bash

# Get current profile
current=$(powerprofilesctl get)

# Options
options="power-saver\nbalanced\nperformance"

# Show menu without theme
chosen=$(echo -e "$options" | rofi -dmenu -p "Power Profile")

# Set profile
if [ -n "$chosen" ]; then
    powerprofilesctl set "$chosen"
fi
