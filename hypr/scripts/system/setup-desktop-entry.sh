#!/bin/bash

# Target directory for user-specific applications
target_dir="$HOME/.local/share/applications"
mkdir -p "$target_dir"

# Smart script path
smart_script="$HOME/.config/hypr/scripts/apps/open-telegram.sh"

# Source desktop file (usually in /usr/share/applications)
# Try to find org.telegram.desktop.desktop or telegram-desktop.desktop
if [ -f "/usr/share/applications/org.telegram.desktop.desktop" ]; then
    source_file="/usr/share/applications/org.telegram.desktop.desktop"
elif [ -f "/usr/share/applications/telegram-desktop.desktop" ]; then
    source_file="/usr/share/applications/telegram-desktop.desktop"
else
    echo "Error: Could not find system Telegram desktop file."
    exit 1
fi

target_file="$target_dir/org.telegram.desktop.desktop"

echo "Installing Smart Telegram desktop entry..."
echo "Source: $source_file"
echo "Target: $target_file"

# Copy the file
cp "$source_file" "$target_file"

# Modify Exec line
# We use sed to replace "Exec=telegram-desktop" or similar with our script
# We start by removing any arguments like -- %u usually found
sed -i "s|^Exec=.*|Exec=$smart_script|" "$target_file"
# Also update Name to indicate it's the smart version (optional, helpful for debugging)
sed -i "s|^Name=Telegram Desktop|Name=Telegram (Smart)|" "$target_file"

# Remove DBusActivatable to force Rofi to use our Exec script
sed -i "/^DBusActivatable=/d" "$target_file"
# Remove TryExec just in case
sed -i "/^TryExec=/d" "$target_file"

# Make executable (though desktop files generally don't strictly need +x, good practice)
chmod +x "$target_file"

echo "Success! Telegram (Smart) is now installed."
echo "You may need to wait a moment for Rofi to pick it up."
