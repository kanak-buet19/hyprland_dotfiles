#!/bin/bash

MONITORS_CONF="$HOME/.config/hypr/conf/monitors.conf"

# Check current mode
if grep -q "3440x1440@200" "$MONITORS_CONF"; then
    MODE="ultrawide"
else
    MODE="cropped"
fi

# Toggle
if [ "$MODE" = "ultrawide" ]; then
    # Switch to cropped 16:9
    cat > "$MONITORS_CONF" << 'EOF'
# Main ultrawide (center) - 2560x1440 at 1.25 scale = 2048 logical width
monitor=DP-6,2560x1440@144,1920x0,1.25
# Laptop (left)
monitor=eDP-2,1920x1080@60,0x0,1
# ASUS vertical (right) - Starts at 3968, centered at -384
monitor=HDMI-A-1,1920x1080@144,3968x-384,1,transform,1
EOF
    notify-send "Monitor Mode" "Switched to 16:9 Cropped"
else
    # Switch to full ultrawide
    cat > "$MONITORS_CONF" << 'EOF'
# Main ultrawide (center) - Logical width is 2752, ends at 4672
monitor=DP-6,3440x1440@200,1920x0,1.25
# Laptop (left) - Ends at 1920
monitor=eDP-2,1920x1080@60,0x0,1
# ASUS vertical (right) - Starts at 4672, centered at -384
monitor=HDMI-A-1,1920x1080@144,4672x-384,1,transform,1
EOF
    notify-send "Monitor Mode" "Switched to Ultrawide 21:9"
fi

# Reload Hyprland config
hyprctl reload
