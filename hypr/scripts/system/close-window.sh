#!/bin/bash

# Get the active window's class
ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [ "$ACTIVE_CLASS" == "org.telegram.desktop" ]; then
    # Get current workspace info
    # We use activewindow to see its workspace
    ACTIVE_WS=$(hyprctl activewindow -j | jq -r '.workspace.name')

    # If it's Telegram, valid or not, move it to the special workspace (minimize it)
    hyprctl dispatch movetoworkspacesilent special:minimized_telegram
else
    # For any other app, kill it as usual
    hyprctl dispatch killactive
fi
