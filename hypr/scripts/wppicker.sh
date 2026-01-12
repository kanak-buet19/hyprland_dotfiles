#!/bin/bash

# === CONFIG ===
# Default start directory
BASE_DIR="$HOME/Pictures"
THUMB_DIR="$BASE_DIR/.thumbs"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"

# Create thumbnail directory if missing
mkdir -p "$THUMB_DIR"

# Allow passing a specific directory as an argument (for recursion)
CURRENT_DIR="${1:-$BASE_DIR}"

# Check if directory exists
if [ ! -d "$CURRENT_DIR" ]; then
    echo "Directory $CURRENT_DIR does not exist"
    exit 1
fi

cd "$CURRENT_DIR" || exit 1

# === GENERATE LIST ===
# 1. Add "Go Back" option if we are not in the base directory
LIST=""
if [ "$CURRENT_DIR" != "$BASE_DIR" ]; then
    LIST+="..\0icon\x1fgo-up\n"
fi

# 2. List Folders first (with folder icon)
for folder in */ ; do
    # Remove trailing slash for display
    [ -d "$folder" ] || continue
    name="${folder%/}"
    # Use standard folder icon or a specific path if you have one
    LIST+="$name\0icon\x1ffolder\n"
done

# 3. List Images (generate thumbs if needed)
for img in *.{jpg,png,jpeg,gif,webp}; do 
    [ -f "$img" ] || continue
    
    # Define thumbnail path (flat structure in .thumbs to avoid complexity)
    # We hash the full path to make a unique filename for the thumb
    full_path="$CURRENT_DIR/$img"
    hash=$(echo -n "$full_path" | md5sum | cut -d' ' -f1)
    thumb="$THUMB_DIR/$hash.jpg"
    
    # Generate thumbnail if missing
    if [ ! -f "$thumb" ]; then
        magick "$img" -thumbnail 300x300 "$thumb"
    fi

    LIST+="$img\0icon\x1f$thumb\n"
done

# === SELECT WITH ROFI ===
SELECTED=$(echo -en "$LIST" | rofi -dmenu -p "Wallpaper" -show-icons \
    -theme-str 'window { width: 50%; }' \
    -theme-str 'listview { columns: 1; lines: 10; }' \
    -theme-str 'element { orientation: horizontal; padding: 5px; spacing: 15px; }' \
    -theme-str 'element-icon { size: 64px; }' \
    -theme-str 'element-text { vertical-align: 0.5; }' \
)

# If no selection, exit
if [ -z "$SELECTED" ]; then
    exit 0
fi

# === HANDLE SELECTION ===

# 1. If "Go Back" (..)
if [ "$SELECTED" = ".." ]; then
    # Go up one level and restart script
    parent=$(dirname "$CURRENT_DIR")
    "$0" "$parent"
    exit 0
fi

# 2. If Selection is a Folder
if [ -d "$CURRENT_DIR/$SELECTED" ]; then
    # Restart script inside that folder
    "$0" "$CURRENT_DIR/$SELECTED"
    exit 0
fi

# 3. If Selection is an Image (Apply Wallpaper)
SELECTED_PATH="$CURRENT_DIR/$SELECTED"

# Update Colors & Wallpaper
matugen image "$SELECTED_PATH"

# Update Symlink
mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"

# Notify
notify-send "Wallpaper Changed" "$SELECTED"