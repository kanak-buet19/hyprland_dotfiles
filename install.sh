#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo "=== Dotfiles Installation Script ==="
echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

# Backup existing configs
echo "[1/4] Backing up existing configs to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

[ -d "$HOME/.config/hypr" ] && mv "$HOME/.config/hypr" "$BACKUP_DIR/"
[ -d "$HOME/.config/waybar" ] && mv "$HOME/.config/waybar" "$BACKUP_DIR/"
[ -d "$HOME/.config/alacritty" ] && mv "$HOME/.config/alacritty" "$BACKUP_DIR/"
[ -d "$HOME/.config/kitty" ] && mv "$HOME/.config/kitty" "$BACKUP_DIR/"
[ -d "$HOME/.config/Code" ] && mv "$HOME/.config/Code" "$BACKUP_DIR/"
[ -f "$HOME/.config/mimeapps.list" ] && mv "$HOME/.config/mimeapps.list" "$BACKUP_DIR/"

# Install packages from pkglist.txt
echo ""
echo "[2/4] Installing packages from pkglist.txt"
if [ -f "$DOTFILES_DIR/pkglist.txt" ]; then
    sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist.txt"
else
    echo "Warning: pkglist.txt not found, skipping package installation"
fi

# Create symlinks
echo ""
echo "[3/4] Creating symlinks"
mkdir -p "$HOME/.config"

ln -sf "$DOTFILES_DIR/hypr" "$HOME/.config/hypr"
ln -sf "$DOTFILES_DIR/waybar" "$HOME/.config/waybar"
ln -sf "$DOTFILES_DIR/alacritty" "$HOME/.config/alacritty"
ln -sf "$DOTFILES_DIR/kitty" "$HOME/.config/kitty"
ln -sf "$DOTFILES_DIR/Code" "$HOME/.config/Code"
ln -sf "$DOTFILES_DIR/mimeapps.list" "$HOME/.config/mimeapps.list"

# Make scripts executable
echo ""
echo "[4/4] Making scripts executable"
if [ -d "$DOTFILES_DIR/hypr/scripts" ]; then
    chmod +x "$DOTFILES_DIR/hypr/scripts"/*
fi

echo ""
echo "=== Installation Complete! ==="
echo "Backup saved to: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "1. Log out and log back into Hyprland"
echo "2. Check if everything works"
echo "3. Delete backup if not needed: rm -rf $BACKUP_DIR"
