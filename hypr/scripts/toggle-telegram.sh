#!/bin/bash
WINDOW_CLASS="org.telegram.desktop"
WORKSPACE=13

# Check if Telegram is running
if ! hyprctl clients -j | jq -e ".[] | select(.class == \"$WINDOW_CLASS\")" > /dev/null; then
    Telegram &
    sleep 2  # Wait for it to spawn on workspace 12
    exit 0
fi

# Check current workspace
CURRENT_WS=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$WINDOW_CLASS\") | .workspace.id")

if [ "$CURRENT_WS" = "$WORKSPACE" ]; then
    # Bring to current workspace
    hyprctl dispatch movetoworkspacesilent m+0,class:$WINDOW_CLASS
    hyprctl dispatch focuswindow class:$WINDOW_CLASS
else
    # Send back to workspace 12
    hyprctl dispatch movetoworkspacesilent $WORKSPACE,class:$WINDOW_CLASS
fi