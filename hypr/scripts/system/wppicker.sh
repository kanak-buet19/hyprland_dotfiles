#!/bin/bash

# === CONFIG ===
BASE_DIR="$HOME/Pictures"
THUMB_DIR="$HOME/.cache/hypr/thumbs"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"

mkdir -p "$THUMB_DIR"
CURRENT_DIR="${1:-$BASE_DIR}"

if [ ! -d "$CURRENT_DIR" ]; then
    echo "Directory $CURRENT_DIR does not exist"
    exit 1
fi

cd "$CURRENT_DIR" || exit 1

# === GENERATE LIST & CACHE ===
# We use a background process to generate thumbs, but we optimize the loop
# Avoiding 'stat' call for every file speeds up the loop significantly.
# We just use the md5 of the "Full Path" as the key. 

(
    for img in *.{jpg,png,jpeg,gif,webp}; do 
        [ -f "$img" ] || continue
        # Hash the PATH string only (no disk IO)
        hash=$(echo -n "$PWD/$img" | md5sum | cut -d' ' -f1)
        thumb="$THUMB_DIR/$hash.jpg"
        
        # Only generate if missing
        if [ ! -f "$thumb" ]; then
            # Optimize generation:
            # -define jpeg:size allows loading partial jpeg (faster)
            # -sample is faster than -resize or -thumbnail (nearest neighbor)
            # 250x250 is enough for grid
            magick "$img" -define jpeg:size=500x500 -sample 250x250 "$thumb"
        fi
    done
) &

LIST=""
# 1. Back button
if [ "$CURRENT_DIR" != "$BASE_DIR" ]; then
    LIST+="..\0icon\x1fgo-up\n"
fi

# 2. Folders
for folder in */ ; do
    [ -d "$folder" ] || continue
    name="${folder%/}"
    LIST+="$name\0icon\x1ffolder\n"
done

# 3. Images
for img in *.{jpg,png,jpeg,gif,webp}; do 
    [ -f "$img" ] || continue
    
    # Same hash logic
    hash=$(echo -n "$PWD/$img" | md5sum | cut -d' ' -f1)
    thumb="$THUMB_DIR/$hash.jpg"

    if [ -f "$thumb" ]; then
        icon="$thumb"
    else
        # CRITICAL OPTIMIZATION:
        # Do NOT load the original image if thumb is missing.
        # Loading 4k/8k images freezes Rofi.
        # Use a generic icon while background gen runs.
        icon="image-x-generic" 
    fi

    LIST+="$img\0icon\x1f$icon\n"
done

# === ROFI CONFIGURATION ===
# Tight grid: 6 columns, tiny spacing/padding
SELECTED=$(echo -en "$LIST" | rofi -dmenu -p "Wallpaper" -show-icons \
    -theme-str 'window { width: 90%; height: 90%; anchor: center; fullscreen: false; }' \
    -theme-str 'listview { columns: 6; lines: 4; spacing: 2px; padding: 2px; layout: vertical; flow: horizontal; fixed-height: false; }' \
    -theme-str 'element { orientation: vertical; padding: 2px; border-radius: 4px; }' \
    -theme-str 'element-icon { size: 250px; horizontal-align: 0.5; vertical-align: 0.5; }' \
    -theme-str 'element-text { vertical-align: 0.5; horizontal-align: 0.5; font: "Sans 10"; }' \
)

if [ -z "$SELECTED" ]; then
    exit 0
fi

if [ "$SELECTED" = ".." ]; then
    parent=$(dirname "$CURRENT_DIR")
    "$0" "$parent"
    exit 0
fi

if [ -d "$CURRENT_DIR/$SELECTED" ]; then
    "$0" "$CURRENT_DIR/$SELECTED"
    exit 0
fi

SELECTED_PATH="$CURRENT_DIR/$SELECTED"
matugen image "$SELECTED_PATH"
mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"
notify-send "Wallpaper Changed" "$SELECTED"