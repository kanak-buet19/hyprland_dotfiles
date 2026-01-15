#!/bin/bash

# Configuration
CORNER_SIZE=3    # Pixels from corner (made slightly larger for easier hitting)
DELAY=0.5         # Seconds to hover
CHECK_INTERVAL=0.1 # Polling rate
REQUIRED_TICKS=$(echo "$DELAY / $CHECK_INTERVAL" | bc)
TRIGGER_CMD="$HOME/.config/hypr/scripts/apps/open-telegram.sh"

# State
COUNTER=0
TRIGGERED=false

# Get Furthest Right X coordinate
# We sum x + width for all monitors and take the maximum
MAX_X=$(hyprctl monitors -j | jq -r '.[] | .x + .width' | sort -rn | head -1)
TARGET_X=$((MAX_X - CORNER_SIZE))

echo "Hot Corner Daemon Started"
echo "Target X > $TARGET_X, Y < $CORNER_SIZE"

while true; do
    # Get position: "123, 456"
    POS=$(hyprctl cursorpos)
    
    # Parse X and Y
    # use comma delimiter, then strip spaces
    X=$(echo "$POS" | cut -d',' -f1 | tr -d ' ')
    Y=$(echo "$POS" | cut -d',' -f2 | tr -d ' ')
    
    # Check if inside top-right corner
    if [ "$X" -gt "$TARGET_X" ] && [ "$Y" -lt "$CORNER_SIZE" ]; then
        if [ "$TRIGGERED" = "false" ]; then
            COUNTER=$((COUNTER + 1))
            
            # echo "Hovering... $COUNTER"
            
            if [ "$COUNTER" -ge "$REQUIRED_TICKS" ]; then
                echo "Triggering Hot Corner!"
                $TRIGGER_CMD &
                TRIGGERED=true
                COUNTER=0
            fi
        fi
    else
        # Left calculation area, reset
        if [ "$COUNTER" -gt 0 ]; then
            COUNTER=0
            # echo "Reset counter"
        fi
        
        # Reset trigger lock only when leaving the area (prevents double trigger)
        TRIGGERED=false
    fi

    sleep "$CHECK_INTERVAL"
done
