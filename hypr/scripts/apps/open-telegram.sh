#!/bin/bash

# Target class for Telegram
# Use 'hyprctl clients' to find the correct class if this doesn't work (usually org.telegram.desktop)
CLASS="org.telegram.desktop"

# Search for the running client
# We get the first instance found
CLIENT=$(hyprctl clients -j | jq -r --arg class "$CLASS" '.[] | select(.class == $class) | "\(.workspace.id)|\(.address)"' | head -n1)

if [ -n "$CLIENT" ]; then
    # Split the result into variables
    WORKSPACE_ID=$(echo "$CLIENT" | cut -d'|' -f1)
    ADDRESS=$(echo "$CLIENT" | cut -d'|' -f2)
    
    echo "Telegram found on workspace $WORKSPACE_ID (Address: $ADDRESS)"
    
    echo "Telegram found on workspace $WORKSPACE_ID (Address: $ADDRESS)"
    
    # Get current active workspace  
    CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')
    
    # Move window to current workspace (this handles both normal and special cases)
    hyprctl dispatch movetoworkspace "$CURRENT_WS,address:$ADDRESS"
    hyprctl dispatch focuswindow "address:$ADDRESS"
else
    echo "Telegram not found. Launching..."
    Telegram &  
fi
