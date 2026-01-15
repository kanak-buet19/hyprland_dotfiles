#!/bin/bash

# Only act if Telegram is focused
ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [ "$ACTIVE_CLASS" == "org.telegram.desktop" ]; then
    # Get current workspace info
    ACTIVE_WS=$(hyprctl activewindow -j | jq -r '.workspace.name')

    if [ "$ACTIVE_WS" == "special:minimized_telegram" ]; then
        # If we are inside the special workspace, toggle it off to hide
        hyprctl dispatch togglespecialworkspace minimized_telegram
    else
        # If normal workspace, move window to special (minimize)
        hyprctl dispatch movetoworkspacesilent special:minimized_telegram
    fi
else
    # DO NOTHING if not Telegram
    echo "Not Telegram, ignoring."
fi
