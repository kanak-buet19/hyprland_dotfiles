#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo "=== Dotfiles Installation Script ==="
echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

# Backup existing configs
echo "[1/5] Backing up existing configs to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

[ -d "$HOME/.config/hypr" ] && mv "$HOME/.config/hypr" "$BACKUP_DIR/"
[ -d "$HOME/.config/waybar" ] && mv "$HOME/.config/waybar" "$BACKUP_DIR/"
[ -d "$HOME/.config/alacritty" ] && mv "$HOME/.config/alacritty" "$BACKUP_DIR/"
[ -d "$HOME/.config/kitty" ] && mv "$HOME/.config/kitty" "$BACKUP_DIR/"
[ -d "$HOME/.config/Code" ] && mv "$HOME/.config/Code" "$BACKUP_DIR/"
[ -f "$HOME/.config/mimeapps.list" ] && mv "$HOME/.config/mimeapps.list" "$BACKUP_DIR/"

# Install yay if not present
echo ""
echo "[2/5] Checking for AUR helper (yay)"
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
else
    echo "yay already installed"
fi

# Install native packages
echo ""
echo "[3/5] Installing native packages from pkglist.txt"
if [ -f "$DOTFILES_DIR/pkglist.txt" ]; then
    sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist.txt"
else
    echo "Warning: pkglist.txt not found"
fi

# Install AUR packages
echo ""
echo "[4/5] Installing AUR packages from pkglist-aur.txt"
if [ -f "$DOTFILES_DIR/pkglist-aur.txt" ]; then
    yay -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist-aur.txt"
else
    echo "Warning: pkglist-aur.txt not found"
fi

# Create symlinks
echo ""
echo "[5/5] Creating symlinks"
mkdir -p "$HOME/.config"

ln -sf "$DOTFILES_DIR/hypr" "$HOME/.config/hypr"
ln -sf "$DOTFILES_DIR/waybar" "$HOME/.config/waybar"
ln -sf "$DOTFILES_DIR/alacritty" "$HOME/.config/alacritty"
ln -sf "$DOTFILES_DIR/kitty" "$HOME/.config/kitty"
ln -sf "$DOTFILES_DIR/Code" "$HOME/.config/Code"
ln -sf "$DOTFILES_DIR/mimeapps.list" "$HOME/.config/mimeapps.list"

# Make scripts executable
if [ -d "$DOTFILES_DIR/hypr/scripts" ]; then
    chmod +x "$DOTFILES_DIR/hypr/scripts"/*
fi

echo ""
echo "=== Installation Complete! ==="
echo "Backup saved to: $BACKUP_DIR"
echo ""
echo "Log out and log back into Hyprland"
