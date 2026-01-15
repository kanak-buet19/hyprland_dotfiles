#!/bin/bash

# Rofi script to search and open folders in VSCode
# If folder is already open, switch to that workspace
# Usage: bind it to a keybinding in Hyprland

# Base directory to search (change this to your projects folder)
BASE_DIR="$HOME"

# Use fd for faster searching, fallback to find if fd not installed
if command -v fd &> /dev/null; then
    # fd searches, then filter: allow .config but exclude other hidden dirs
    FOLDERS=$(fd -t d -d 5 -H . "$BASE_DIR" 2>/dev/null | grep -v -E "\.git/|node_modules/" | grep -E "^[^.]+|\.config")
else
    # Fallback to find
    FOLDERS=$(find "$BASE_DIR" -maxdepth 5 -type d 2>/dev/null | grep -v -E "\.git/|node_modules/" | grep -E "/[^.][^/]*$|\.config")
fi

# Check if we found any folders
if [ -z "$FOLDERS" ]; then
    notify-send "Error" "No folders found in $BASE_DIR" -t 3000
    exit 1
fi

# Show folders in rofi and get selection
SELECTED=$(echo "$FOLDERS" | rofi -dmenu -i -p "Open folder in VSCode" -matching glob -theme-str 'window {width: 50%;}')

# Exit if nothing selected
if [ -z "$SELECTED" ]; then
    exit 0
fi

# Verify it's a valid directory
if [ ! -d "$SELECTED" ]; then
    notify-send "Error" "Not a valid directory" -t 2000
    exit 1
fi

# Get the folder name we're looking for
SELECTED_FOLDER=$(basename "$SELECTED")

# Get all VSCode windows with their workspace IDs and window titles
# First, let's see what classes VSCode actually uses
echo "=== ALL CLIENTS (checking class names) ==="
hyprctl clients -j | jq -r '.[] | "\(.class)|\(.initialClass)"' | sort | uniq
echo ""

echo "=== TRYING DIFFERENT FILTERS ==="
echo "Filter 1: class==Code"
hyprctl clients -j | jq '.[] | select(.class=="Code")'
echo ""
echo "Filter 2: initialClass==Code"  
hyprctl clients -j | jq '.[] | select(.initialClass=="Code")'
echo ""
echo "Filter 3: class contains code (case insensitive)"
hyprctl clients -j | jq '.[] | select(.class | ascii_downcase | contains("code"))'
echo ""

# Try to get ANY VSCode window
VSCODE_INFO=$(hyprctl clients -j | jq -r '.[] | select(.class | ascii_downcase | contains("code")) | "\(.workspace.id)|\(.title)|\(.address)"')

# DEBUG: Print what we found
echo "=== DEBUG: VSCode Windows Found ==="
echo "$VSCODE_INFO"
echo "=== Total windows: $(echo "$VSCODE_INFO" | grep -v '^

# Check if any VSCode instance has this folder open
FOUND_WORKSPACE=""
FOUND_ADDRESS=""

while IFS='|' read -r ws_id title address; do
    echo "--- Checking Window ---"
    echo "Workspace ID: $ws_id"
    echo "Title: $title"
    echo "Address: $address"
    
    # VSCode title format is usually: "filename - foldername - Visual Studio Code"
    # Extract folder name from title (it's usually before " - Visual Studio Code")
    TITLE_FOLDER=$(echo "$title" | sed 's/ - Visual Studio Code$//' | rev | cut -d'-' -f1 | rev | xargs)
    
    echo "Extracted folder from title: '$TITLE_FOLDER'"
    echo "Comparing with: '$SELECTED_FOLDER'"
    
    # Check if the folder name matches
    if [[ "$TITLE_FOLDER" == "$SELECTED_FOLDER" ]] || echo "$title" | grep -q "$SELECTED_FOLDER"; then
        FOUND_WORKSPACE="$ws_id"
        FOUND_ADDRESS="$address"
        echo "*** MATCH FOUND! ***"
        echo ""
        break
    else
        echo "No match"
        echo ""
    fi
done <<< "$VSCODE_INFO"

# If found, switch to that workspace
if [ -n "$FOUND_WORKSPACE" ]; then
    echo "=== SWITCHING TO WORKSPACE $FOUND_WORKSPACE ==="
    hyprctl dispatch workspace "$FOUND_WORKSPACE"
    sleep 0.3
    echo "=== FOCUSING WINDOW $FOUND_ADDRESS ==="
    hyprctl dispatch focuswindow "address:$FOUND_ADDRESS"
    notify-send "VSCode" "Switched to workspace $FOUND_WORKSPACE" -t 2000
    echo "=== DONE ==="
else
    echo "=== NO MATCH - OPENING NEW WINDOW ==="
    # Not found - open in current workspace
    code "$SELECTED" &
    notify-send "VSCode" "Opening: $SELECTED_FOLDER" -t 2000
fi
 | wc -l) ==="
echo ""
echo "Selected folder: $SELECTED_FOLDER"
echo "Selected path: $SELECTED"
echo ""

# Check if any VSCode instance has this folder open
FOUND_WORKSPACE=""
FOUND_ADDRESS=""

while IFS='|' read -r ws_id title address; do
    echo "--- Checking Window ---"
    echo "Workspace ID: $ws_id"
    echo "Title: $title"
    echo "Address: $address"
    
    # VSCode title format is usually: "filename - foldername - Visual Studio Code"
    # Extract folder name from title (it's usually before " - Visual Studio Code")
    TITLE_FOLDER=$(echo "$title" | sed 's/ - Visual Studio Code$//' | rev | cut -d'-' -f1 | rev | xargs)
    
    echo "Extracted folder from title: '$TITLE_FOLDER'"
    echo "Comparing with: '$SELECTED_FOLDER'"
    
    # Check if the folder name matches
    if [[ "$TITLE_FOLDER" == "$SELECTED_FOLDER" ]] || echo "$title" | grep -q "$SELECTED_FOLDER"; then
        FOUND_WORKSPACE="$ws_id"
        FOUND_ADDRESS="$address"
        echo "*** MATCH FOUND! ***"
        echo ""
        break
    else
        echo "No match"
        echo ""
    fi
done <<< "$VSCODE_INFO"

# If found, switch to that workspace
if [ -n "$FOUND_WORKSPACE" ]; then
    echo "=== SWITCHING TO WORKSPACE $FOUND_WORKSPACE ==="
    hyprctl dispatch workspace "$FOUND_WORKSPACE"
    sleep 0.3
    echo "=== FOCUSING WINDOW $FOUND_ADDRESS ==="
    hyprctl dispatch focuswindow "address:$FOUND_ADDRESS"
    notify-send "VSCode" "Switched to workspace $FOUND_WORKSPACE" -t 2000
    echo "=== DONE ==="
else
    echo "=== NO MATCH - OPENING NEW WINDOW ==="
    # Not found - open in current workspace
    code "$SELECTED" &
    notify-send "VSCode" "Opening: $SELECTED_FOLDER" -t 2000
fi