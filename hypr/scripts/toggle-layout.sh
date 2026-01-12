#!/bin/bash

# Get current workspace ID
WS_ID=$(hyprctl activeworkspace -j | jq '.id')
STATE_FILE="/tmp/hypr_layout_ws_${WS_ID}"

# Read current state (Default to 'dwindle' if no file exists)
if [ ! -f "$STATE_FILE" ]; then
    CURRENT="dwindle"
else
    CURRENT=$(cat "$STATE_FILE")
fi

# Toggle Logic
if [ "$CURRENT" == "dwindle" ]; then
    hyprctl dispatch layoutmsg setlayout master
    notify-send -t 1000 "Layout" "Switched to Master"
    echo "master" > "$STATE_FILE"
else
    hyprctl dispatch layoutmsg setlayout dwindle
    notify-send -t 1000 "Layout" "Switched to Dwindle"
    echo "dwindle" > "$STATE_FILE"
fi