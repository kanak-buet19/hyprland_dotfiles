#!/bin/bash

# Robust dotfiles installation script with error handling and reporting

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$DOTFILES_DIR/install.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Arrays to track status
declare -a SUCCEEDED
declare -a FAILED
declare -a SKIPPED

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Status tracking functions
mark_success() {
    SUCCEEDED+=("$1")
    log "${GREEN}✓${NC} $1"
}

mark_failed() {
    FAILED+=("$1")
    log "${RED}✗${NC} $1"
}

mark_skipped() {
    SKIPPED+=("$1")
    log "${YELLOW}⊘${NC} $1"
}

# Clear log file
> "$LOG_FILE"

log "${BLUE}=== Dotfiles Installation Script ===${NC}"
log "Dotfiles directory: $DOTFILES_DIR"
log "Log file: $LOG_FILE"
log ""

# ======================
# STEP 1: Initialize backup and symlink lists
# ======================
log "${BLUE}[1/7] Initializing configuration${NC}"

# Known/standard configs
backup_items=(
    "$HOME/.config/hypr"
    "$HOME/.config/waybar"
    "$HOME/.config/alacritty"
    "$HOME/.config/Code"
    "$HOME/.config/rofi"
    "$HOME/.config/wireplumber"
    "$HOME/.config/mimeapps.list"
)

symlinks=(
    "hypr:$HOME/.config/hypr"
    "waybar:$HOME/.config/waybar"
    "alacritty:$HOME/.config/alacritty"
    "Code:$HOME/.config/Code"
    "rofi:$HOME/.config/rofi"
    "wireplumber:$HOME/.config/wireplumber"
    "mimeapps.list:$HOME/.config/mimeapps.list"
)

mark_success "Initialized with ${#symlinks[@]} standard configs"
log ""

# ======================
# STEP 2: Discover additional configs
# ======================
log "${BLUE}[2/7] Discovering additional configs in dotfiles${NC}"

# Known configs that are already handled
known_configs=("hypr" "waybar" "alacritty" "Code" "rofi" "wireplumber" "mimeapps.list")

# Find additional config directories in dotfiles
additional_configs=()
for dir in "$DOTFILES_DIR"/*; do
    if [ -d "$dir" ]; then
        dir_name=$(basename "$dir")
        # Skip if it's a known config or special directory
        if [[ ! " ${known_configs[@]} " =~ " ${dir_name} " ]] && \
           [[ ! "$dir_name" =~ ^(\.git|scripts|web-apps)$ ]] && \
           [[ ! "$dir_name" =~ ^\. ]]; then
            # Check if it looks like a config directory (has files)
            if [ "$(find "$dir" -maxdepth 1 -type f | wc -l)" -gt 0 ]; then
                additional_configs+=("$dir_name")
            fi
        fi
    fi
done

if [ ${#additional_configs[@]} -gt 0 ]; then
    log ""
    log "${YELLOW}Found additional configs in dotfiles:${NC}"
    for i in "${!additional_configs[@]}"; do
        log "  $((i+1))) ${additional_configs[$i]}"
    done
    log ""
    log "Install these configs? Enter numbers (space-separated, e.g., '1 2 3'), 'all', or 'n' to skip:"
    read -r selection
    
    selected_configs=()
    if [ "$selection" = "all" ]; then
        selected_configs=("${additional_configs[@]}")
        log "Selected all additional configs"
    elif [ "$selection" != "n" ] && [ -n "$selection" ]; then
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#additional_configs[@]}" ]; then
                selected_configs+=("${additional_configs[$((num-1))]}")
            fi
        done
    fi
    
    if [ ${#selected_configs[@]} -gt 0 ]; then
        log "Will install: ${selected_configs[*]}"
        # Add to backup and symlink lists
        for config in "${selected_configs[@]}"; do
            backup_items+=("$HOME/.config/$config")
            symlinks+=("$config:$HOME/.config/$config")
            mark_success "Added $config to installation list"
        done
    else
        mark_skipped "No additional configs selected"
    fi
else
    mark_skipped "No additional configs found"
fi
log ""

# ======================
# STEP 3: Backup configs
# ======================
log "${BLUE}[3/7] Backing up existing configs${NC}"
mkdir -p "$BACKUP_DIR"

for item in "${backup_items[@]}"; do
    if [ -e "$item" ]; then
        if mv "$item" "$BACKUP_DIR/" 2>/dev/null; then
            mark_success "Backed up: $(basename "$item")"
        else
            mark_failed "Failed to backup: $(basename "$item")"
        fi
    fi
done

log "Backup directory: $BACKUP_DIR"
log ""

# ======================
# STEP 4: Install yay
# ======================
log "${BLUE}[4/7] Checking for AUR helper (yay)${NC}"

if command -v yay &> /dev/null; then
    mark_skipped "yay already installed"
else
    log "Installing yay..."
    if sudo pacman -S --needed --noconfirm git base-devel 2>/dev/null; then
        cd /tmp
        if git clone https://aur.archlinux.org/yay.git 2>/dev/null; then
            cd yay
            if makepkg -si --noconfirm 2>/dev/null; then
                mark_success "yay installed"
            else
                mark_failed "yay build failed"
            fi
        else
            mark_failed "yay clone failed"
        fi
        cd "$DOTFILES_DIR"
    else
        mark_failed "git/base-devel installation failed"
    fi
fi
log ""

# ======================
# STEP 5: Install official packages
# ======================
log "${BLUE}[5/7] Installing official packages${NC}"

if [ ! -f "$DOTFILES_DIR/pkglist.txt" ]; then
    mark_failed "pkglist.txt not found"
else
    # Separate official and AUR packages
    official_pkgs=()
    aur_pkgs=()

    while IFS= read -r pkg; do
        # Skip empty lines and comments
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

        # Check if package exists in official repos
        if pacman -Si "$pkg" &>/dev/null; then
            official_pkgs+=("$pkg")
        else
            aur_pkgs+=("$pkg")
        fi
    done < "$DOTFILES_DIR/pkglist.txt"

    log "Found ${#official_pkgs[@]} official packages, ${#aur_pkgs[@]} AUR packages"

    # Install official packages
    if [ ${#official_pkgs[@]} -gt 0 ]; then
        failed_official=()
        for pkg in "${official_pkgs[@]}"; do
            if pacman -Q "$pkg" &>/dev/null; then
                mark_skipped "$pkg (already installed)"
            else
                if sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null; then
                    mark_success "$pkg"
                else
                    mark_failed "$pkg"
                    failed_official+=("$pkg")
                fi
            fi
        done
    fi
fi
log ""

# ======================
# STEP 6: Install AUR packages
# ======================
log "${BLUE}[6/7] Installing AUR packages${NC}"

# Combine AUR packages from both files
all_aur_pkgs=("${aur_pkgs[@]}")

if [ -f "$DOTFILES_DIR/pkglist-aur.txt" ]; then
    while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
        all_aur_pkgs+=("$pkg")
    done < "$DOTFILES_DIR/pkglist-aur.txt"
fi

# Remove duplicates
all_aur_pkgs=($(printf "%s\n" "${all_aur_pkgs[@]}" | sort -u))

if [ ${#all_aur_pkgs[@]} -eq 0 ]; then
    mark_skipped "No AUR packages to install"
else
    if ! command -v yay &> /dev/null; then
        mark_failed "yay not available, cannot install AUR packages"
    else
        log "Installing ${#all_aur_pkgs[@]} AUR packages..."
        failed_aur=()
        for pkg in "${all_aur_pkgs[@]}"; do
            if pacman -Q "$pkg" &>/dev/null; then
                mark_skipped "$pkg (already installed)"
            else
                if yay -S --needed --noconfirm "$pkg" 2>/dev/null; then
                    mark_success "$pkg"
                else
                    mark_failed "$pkg"
                    failed_aur+=("$pkg")
                fi
            fi
        done
    fi
fi
log ""

# ======================
# STEP 7: Create symlinks
# ======================
log "${BLUE}[7/7] Creating symlinks${NC}"
mkdir -p "$HOME/.config"

for link_pair in "${symlinks[@]}"; do
    IFS=':' read -r source target <<< "$link_pair"
    source_path="$DOTFILES_DIR/$source"

    if [ ! -e "$source_path" ]; then
        mark_failed "Source not found: $source"
        continue
    fi

    # Remove existing symlink/file
    [ -e "$target" ] && rm -rf "$target" 2>/dev/null

    if ln -sf "$source_path" "$target" 2>/dev/null; then
        mark_success "Linked: $source → $(basename "$target")"
    else
        mark_failed "Failed to link: $source"
    fi
done

# Make scripts executable
if [ -d "$DOTFILES_DIR/hypr/scripts" ]; then
    if chmod +x "$DOTFILES_DIR/hypr/scripts"/* 2>/dev/null; then
        mark_success "Made hypr scripts executable"
    else
        mark_failed "Failed to make scripts executable"
    fi
fi

# Install web apps
if [ -d "$DOTFILES_DIR/web-apps" ]; then
    mkdir -p "$HOME/.local/share/applications"
    for app in "$DOTFILES_DIR/web-apps"/*.desktop; do
        if [ -f "$app" ]; then
            app_name=$(basename "$app")
            if cp "$app" "$HOME/.local/share/applications/" 2>/dev/null; then
                mark_success "Installed web app: $app_name"
            else
                mark_failed "Failed to install: $app_name"
            fi
        fi
    done
    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null && mark_success "Updated desktop database"
fi

log ""

# ======================
# SUMMARY REPORT
# ======================
log "${BLUE}==================== INSTALLATION SUMMARY ====================${NC}"
log ""

log "${GREEN}✓ SUCCEEDED (${#SUCCEEDED[@]}):${NC}"
if [ ${#SUCCEEDED[@]} -eq 0 ]; then
    log "  None"
else
    for item in "${SUCCEEDED[@]}"; do
        log "  - $item"
    done
fi
log ""

log "${YELLOW}⊘ SKIPPED (${#SKIPPED[@]}):${NC}"
if [ ${#SKIPPED[@]} -eq 0 ]; then
    log "  None"
else
    for item in "${SKIPPED[@]}"; do
        log "  - $item"
    done
fi
log ""

log "${RED}✗ FAILED (${#FAILED[@]}):${NC}"
if [ ${#FAILED[@]} -eq 0 ]; then
    log "  None - Perfect installation!"
else
    for item in "${FAILED[@]}"; do
        log "  - $item"
    done
fi
log ""

# ======================
# TROUBLESHOOTING TIPS
# ======================
if [ ${#FAILED[@]} -gt 0 ]; then
    log "${BLUE}==================== TROUBLESHOOTING ====================${NC}"
    log ""
    log "${YELLOW}How to fix failed items:${NC}"
    log ""

    # Check for common failures
    has_pkg_failures=false
    for item in "${FAILED[@]}"; do
        if [[ ! "$item" =~ "Backed up" && ! "$item" =~ "link" && ! "$item" =~ "script" ]]; then
            has_pkg_failures=true
            break
        fi
    done

    if [ "$has_pkg_failures" = true ]; then
        log "📦 ${YELLOW}Package installation failures:${NC}"
        log "   Try installing failed packages manually:"
        log "   ${BLUE}sudo pacman -S <package-name>${NC}  # for official repos"
        log "   ${BLUE}yay -S <package-name>${NC}          # for AUR packages"
        log ""
        log "   Check package names - they might be:"
        log "   - Renamed or removed from repos"
        log "   - Require different repo (multilib, etc.)"
        log "   - Have dependency conflicts"
        log ""
        log "   View detailed errors in: $LOG_FILE"
        log ""
    fi

    for item in "${FAILED[@]}"; do
        if [[ "$item" =~ "yay" ]]; then
            log "🔧 ${YELLOW}yay installation failed:${NC}"
            log "   Install manually:"
            log "   ${BLUE}cd /tmp && git clone https://aur.archlinux.org/yay.git${NC}"
            log "   ${BLUE}cd yay && makepkg -si${NC}"
            log ""
        fi

        if [[ "$item" =~ "link" ]]; then
            log "🔗 ${YELLOW}Symlink failures:${NC}"
            log "   Check permissions and paths:"
            log "   ${BLUE}ls -la ~/.config/${NC}"
            log "   ${BLUE}ls -la $DOTFILES_DIR${NC}"
            log ""
        fi
    done

    log "${YELLOW}Need more help?${NC}"
    log "   1. Check full log: ${BLUE}cat $LOG_FILE${NC}"
    log "   2. Search Arch Wiki: ${BLUE}https://wiki.archlinux.org${NC}"
    log "   3. Check AUR package pages for specific issues"
    log ""
fi

log "${BLUE}=============================================================${NC}"
log ""
log "Backup saved to: ${BLUE}$BACKUP_DIR${NC}"
log "Full log saved to: ${BLUE}$LOG_FILE${NC}"
log ""

if [ ${#FAILED[@]} -eq 0 ]; then
    log "${GREEN}✓ Installation completed successfully!${NC}"
    log "${YELLOW}Next steps:${NC}"
    log "   1. Log out of your current session"
    log "   2. Log back into Hyprland"
    log "   3. Enjoy your new setup!"
else
    log "${YELLOW}⚠ Installation completed with some failures${NC}"
    log "   Review the summary above and fix failed items"
    log "   You can re-run this script after fixing issues"
fi
log "
