#!/bin/bash

# Socket path
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# Function to handle bindings
handle_focus() {
    # Check if the focused window is Telegram
    # We use activewindow -j for reliability
    CLASS=$(hyprctl activewindow -j | jq -r '.class')
    
    if [ "$CLASS" == "org.telegram.desktop" ]; then
        # Bind ESC to hide-telegram (safe version)
        echo "Telegram focused: Binding ESC"
        hyprctl keyword bind , Escape, exec, ~/.config/hypr/scripts/apps/hide-telegram.sh
    else
        # Unbind ESC to restore default behavior (sending key to app)
        # We suppress error output in case it wasn't bound
        echo "Telegram lost focus: Unbinding ESC"
        hyprctl keyword unbind , Escape
    fi
}

# Initial check on startup
handle_focus

# Listen for events
# We use socat to connect to the socket
socat -U - UNIX-CONNECT:"$SOCKET" | while read -r line; do
    case "$line" in
        activewindow*)
            handle_focus
            ;;
    esac
done
