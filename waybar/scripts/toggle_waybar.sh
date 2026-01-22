#!/bin/bash

# Define paths
CONFIG_DIR="$HOME/hyprland_dotfiles/waybar"
CONFIG_HORIZONTAL="$CONFIG_DIR/config"
STYLE_HORIZONTAL="$CONFIG_DIR/style.css"
CONFIG_VERTICAL="$CONFIG_DIR/config-vertical"
STYLE_VERTICAL="$CONFIG_DIR/style-vertical.css"

# Check if waybar is running and with which config
# We look for the running process command line args to determine current state
if pgrep -f "waybar -c $CONFIG_VERTICAL" > /dev/null; then
    echo "Switching to Horizontal..."
    killall waybar
    waybar -c "$CONFIG_HORIZONTAL" -s "$STYLE_HORIZONTAL" &
    notify-send "Waybar" "Switched to Horizontal Mode"
else
    echo "Switching to Vertical..."
    killall waybar
    # If not running, or running default, switch to vertical
    waybar -c "$CONFIG_VERTICAL" -s "$STYLE_VERTICAL" &
    notify-send "Waybar" "Switched to Vertical Mode"
fi
