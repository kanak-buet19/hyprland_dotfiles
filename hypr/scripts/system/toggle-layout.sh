#!/bin/bash
WS_ID=$(hyprctl activeworkspace -j | jq '.id')
STATE_FILE="/tmp/hypr_layout_ws_${WS_ID}"

WINDOWS=$(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $WS_ID) | .class")
HAS_VSCODE=$(echo "$WINDOWS" | grep -iq "code" && echo "yes" || echo "no")
HAS_ZATHURA=$(echo "$WINDOWS" | grep -iq "zathura" && echo "yes" || echo "no")

if [ "$HAS_VSCODE" = "yes" ] && [ "$HAS_ZATHURA" = "yes" ]; then
    INITIAL="dwindle"
else
    INITIAL="master"
fi

if [ ! -f "$STATE_FILE" ]; then
    LAYOUT="$INITIAL"
else
    CURRENT=$(cat "$STATE_FILE")
    [ "$CURRENT" = "master" ] && LAYOUT="dwindle" || LAYOUT="master"
fi

hyprctl dispatch layoutmsg setlayout "$LAYOUT"
notify-send -t 1000 "WS$WS_ID" "$LAYOUT"
echo "$LAYOUT" > "$STATE_FILE"