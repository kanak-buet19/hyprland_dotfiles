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
(
    # Generate thumbnails for images
    for img in *.{jpg,png,jpeg,gif,webp}; do 
        [ -f "$img" ] || continue
        hash=$(echo -n "$PWD/$img" | md5sum | cut -d' ' -f1)
        thumb="$THUMB_DIR/$hash.jpg"
        if [ ! -f "$thumb" ]; then
            magick "$img" -define jpeg:size=500x500 -sample 250x250 "$thumb" 2>/dev/null
        fi
    done
    
    # Generate thumbnails for videos
    for vid in *.{mp4,mkv,webm,avi,mov}; do
        [ -f "$vid" ] || continue
        hash=$(echo -n "$PWD/$vid" | md5sum | cut -d' ' -f1)
        thumb="$THUMB_DIR/$hash.jpg"
        if [ ! -f "$thumb" ]; then
            ffmpeg -i "$vid" -vframes 1 -vf scale=250:250:force_original_aspect_ratio=decrease -y "$thumb" 2>/dev/null
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
    hash=$(echo -n "$PWD/$img" | md5sum | cut -d' ' -f1)
    thumb="$THUMB_DIR/$hash.jpg"
    if [ -f "$thumb" ]; then
        icon="$thumb"
    else
        icon="image-x-generic" 
    fi
    LIST+="$img\0icon\x1f$icon\n"
done

# 4. Videos
for vid in *.{mp4,mkv,webm,avi,mov}; do
    [ -f "$vid" ] || continue
    hash=$(echo -n "$PWD/$vid" | md5sum | cut -d' ' -f1)
    thumb="$THUMB_DIR/$hash.jpg"
    if [ -f "$thumb" ]; then
        icon="$thumb"
    else
        icon="video-x-generic"
    fi
    LIST+="$vid\0icon\x1f$icon\n"
done

# === ROFI CONFIGURATION ===
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

# Handle back navigation
if [ "$SELECTED" = ".." ]; then
    parent=$(dirname "$CURRENT_DIR")
    "$0" "$parent"
    exit 0
fi

# Handle folder navigation
if [ -d "$CURRENT_DIR/$SELECTED" ]; then
    "$0" "$CURRENT_DIR/$SELECTED"
    exit 0
fi

SELECTED_PATH="$CURRENT_DIR/$SELECTED"

# Check if selected file is a video
if [[ "$SELECTED_PATH" =~ \.(mp4|mkv|webm|avi|mov)$ ]]; then
    # Kill existing wallpaper processes
    pkill hyprpaper 2>/dev/null
    pkill mpvpaper 2>/dev/null
    
    # Start video wallpaper with mpvpaper
    mpvpaper -o "loop" '*' "$SELECTED_PATH" &
    
    # Update symlink
    mkdir -p "$(dirname "$SYMLINK_PATH")"
    ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"
    
    notify-send "Video Wallpaper Changed" "$SELECTED"
else
    # Kill mpvpaper if running
    pkill mpvpaper 2>/dev/null
    
    # Use matugen for static images
    matugen image "$SELECTED_PATH"
    
    # Update symlink
    mkdir -p "$(dirname "$SYMLINK_PATH")"
    ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"
    
    notify-send "Wallpaper Changed" "$SELECTED"
fi