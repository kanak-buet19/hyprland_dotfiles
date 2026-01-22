#!/usr/bin/env bash

# Direction: l, r, u, d
DIR=$1

if [ -z "$DIR" ]; then
    echo "Usage: $0 <direction>"
    exit 1
fi

# Get current window info
WINDOW_INFO=$(hyprctl activewindow -j)
MON_BEFORE=$(echo "$WINDOW_INFO" | jq -r '.monitor')
POS_BEFORE=$(echo "$WINDOW_INFO" | jq -r '.at')

# Try to move window
hyprctl dispatch movewindow "$DIR"

# Get new window info
WINDOW_INFO_AFTER=$(hyprctl activewindow -j)
MON_AFTER=$(echo "$WINDOW_INFO_AFTER" | jq -r '.monitor')
POS_AFTER=$(echo "$WINDOW_INFO_AFTER" | jq -r '.at')

# Check if window actually moved
# If Monitor changed, it moved.
# If Position changed, it moved.
if [ "$MON_BEFORE" == "$MON_AFTER" ] && [ "$POS_BEFORE" == "$POS_AFTER" ]; then
    # Window didn't move, so we force it to next/prev workspace
    # Moving Right -> Next Workspace (+1)
    # Moving Left -> Prev Workspace (-1)
    # Up/Down can map similarly or be ignored based on preference.
    
    case $DIR in
        r)
            hyprctl dispatch movetoworkspace +1
            ;;
        l)
            hyprctl dispatch movetoworkspace -1
            ;;
        u)
            hyprctl dispatch movetoworkspace -1
            ;;
        d)
            hyprctl dispatch movetoworkspace +1
            ;;
    esac
fi
