#!/bin/bash

# === CONFIG ===
WALLPAPER_DIR="$HOME/Pictures/wallpaper"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"

# Check if directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Directory $WALLPAPER_DIR does not exist"
    exit 1
fi

cd "$WALLPAPER_DIR" || exit 1

# === HANDLE SPACES IN FILENAMES ===
IFS=$'\n'

# === SELECT WALLPAPER (Grid View Override) ===
# We pass -theme-str options to override the look just for this menu
SELECTED_WALL=$(for a in $(ls -t *.{jpg,png,jpeg,gif} 2>/dev/null); do 
    echo -en "$a\0icon\x1f$WALLPAPER_DIR/$a\n"
done | rofi -dmenu -p "Wallpaper" -show-icons \
    -theme-str 'window { width: 60%; }' \
    -theme-str 'listview { columns: 4; lines: 3; }' \
    -theme-str 'element { orientation: vertical; padding: 10px; }' \
    -theme-str 'element-icon { size: 120px; }' \
    -theme-str 'element-text { horizontal-align: 0.5; }' \
)

# If no selection, exit
if [ -z "$SELECTED_WALL" ]; then
    exit 0
fi

SELECTED_PATH="$WALLPAPER_DIR/$SELECTED_WALL"

# === APPLY SETTINGS ===
# 1. Update Colors & Wallpaper
matugen image "$SELECTED_PATH"

# 2. Update Symlink
mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"

# 3. Notify
notify-send "Wallpaper Changed" "$SELECTED_WALL"
