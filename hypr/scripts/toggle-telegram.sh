#!/bin/bash
WINDOW_CLASS="org.telegram.desktop"
SPECIAL_WS="special:telegram"

# Check if Telegram is running
if ! hyprctl clients -j | jq -e ".[] | select(.class == \"$WINDOW_CLASS\")" > /dev/null; then
    telegram-desktop &
    exit 0
fi

# Check current workspace of Telegram
CURRENT_WS=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$WINDOW_CLASS\") | .workspace.name")

if [ "$CURRENT_WS" = "$SPECIAL_WS" ]; then
    # Telegram is in special workspace, bring to active workspace
    ACTIVE_WS=$(hyprctl activeworkspace -j | jq -r '.id')
    hyprctl dispatch movetoworkspacesilent $ACTIVE_WS,class:$WINDOW_CLASS
    hyprctl dispatch focuswindow class:$WINDOW_CLASS
else
    # Telegram is visible, send back to special workspace
    hyprctl dispatch movetoworkspacesilent $SPECIAL_WS,class:$WINDOW_CLASS
fi