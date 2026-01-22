#!/bin/bash

# Arch Linux Safe Update Script
# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MIN_PACKAGE_AGE_DAYS=30  # Wait 7 days after package release before updating
CRITICAL_PACKAGES=("linux" "linux-headers" "nvidia" "nvidia-dkms" "systemd" "grub" "btrfs-progs")

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Arch Linux Safe Update Tool${NC}"
echo -e "${BLUE}================================${NC}\n"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Don't run this script as root!${NC}"
   exit 1
fi

# Function to check if package is old enough
check_package_age() {
    local pkg=$1
    # Force LANG=C to ensure standard date format (e.g. "Build Date : ...")
    local build_date=$(LANG=C pacman -Si "$pkg" 2>/dev/null | grep "Build Date" | cut -d':' -f2- | xargs)
    
    if [[ -z "$build_date" ]]; then
        echo "unknown"
        return 1
    fi
    
    local build_epoch=$(date -d "$build_date" +%s 2>/dev/null)
    local current_epoch=$(date +%s)

    if [[ -z "$build_epoch" || "$build_epoch" -eq 0 ]]; then
        echo "unknown"
        return 1
    fi

    local age_days=$(( (current_epoch - build_epoch) / 86400 ))
    
    echo "$age_days"
}

# Step 1: Check Arch News
echo -e "${YELLOW}[1/7] Checking Arch Linux News...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

NEWS_FOUND=false

if command -v yay &> /dev/null; then
    NEWS_OUTPUT=$(yay -Pw 2>&1)
    if [[ -n "$NEWS_OUTPUT" ]]; then
        echo "$NEWS_OUTPUT"
        NEWS_FOUND=true
    fi
elif command -v paru &> /dev/null; then
    NEWS_OUTPUT=$(paru -Pw 2>&1)
    if [[ -n "$NEWS_OUTPUT" ]]; then
        echo "$NEWS_OUTPUT"
        NEWS_FOUND=true
    fi
fi

if [[ "$NEWS_FOUND" == false ]]; then
    echo "Fetching latest news from archlinux.org..."
    NEWS_DATA=$(curl -s https://archlinux.org/feeds/news/)
    
    if [[ -z "$NEWS_DATA" ]]; then
        echo -e "${RED}Failed to fetch news (no internet?). Check manually at: https://archlinux.org/news/${NC}"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    else
        # Parse and display news nicely
        echo "$NEWS_DATA" | grep -oP '(?<=<title>).*?(?=</title>)' | grep -v "^Arch Linux: Recent news updates$" | head -5 | nl -w2 -s'. '
        echo ""
        echo -e "${BLUE}Full news: https://archlinux.org/news/${NC}"
    fi
fi

echo ""
read -p "Have you read the news above? Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Update cancelled.${NC}"
    exit 0
fi

# Step 2: Create Timeshift Snapshot

echo -e "\n${YELLOW}[2/7] Creating Snapper Snapshot...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# if ! command -v timeshift &> /dev/null; then
#     echo -e "${RED}Timeshift not installed! Install it first: sudo pacman -S timeshift${NC}"
#     exit 1
# fi

if ! command -v snapper &> /dev/null; then
    echo -e "${RED}Snapper not installed! Install it: sudo pacman -S snapper${NC}"
    exit 1
fi

echo "Creating pre-update snapshot..."
sudo snapper -c root create --description "Pre-update $(date +%Y-%m-%d_%H:%M)" --type pre

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Snapshot creation failed! Aborting update.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Snapshot created successfully${NC}"

# Step 3: Check, Analyze & List Updates
echo -e "\n${YELLOW}[3/7] Checking Available Updates & Package Ages...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v checkupdates &> /dev/null; then
    UPDATES=$(checkupdates)
else
    UPDATES=$(pacman -Qu)
fi

if [[ -z "$UPDATES" ]]; then
    echo -e "${GREEN}System is up to date!${NC}"
    exit 0
fi

UPDATE_COUNT=$(echo "$UPDATES" | wc -l)
echo -e "${BLUE}Found $UPDATE_COUNT updates. analyzing...${NC}\n"

# Table Header
printf "${BLUE}%-30s %-25s %-15s %s${NC}\n" "Package" "Version" "Age" "Status"
echo "--------------------------------------------------------------------------------"

CRITICAL_UPDATES=()
YOUNG_PACKAGES=()
REBOOT_NEEDED=false

while IFS= read -r line; do
    # checkupdates output format: package old_ver -> new_ver
    # We need to handle potential parsing differences if using pacman -Qu
    
    pkg_name=$(echo "$line" | awk '{print $1}')
    # Extract version info if available in "old -> new" format (standard for checkupdates)
    version_info=$(echo "$line" | awk '{$1=""; print $0}' | xargs)
    
    # Calculate age
    age=$(check_package_age "$pkg_name")
    
    status_str=""
    age_str=""
    
    # Check Critical
    is_crit=false
    for cpkg in "${CRITICAL_PACKAGES[@]}"; do
        if [[ "$pkg_name" == "$cpkg" ]]; then
            is_crit=true
            CRITICAL_UPDATES+=("$pkg_name")
            if [[ "$pkg_name" == "linux" || "$pkg_name" == "nvidia"* || "$pkg_name" == "systemd" ]]; then
                REBOOT_NEEDED=true
            fi
            break
        fi
    done
    
    # Check Age
    is_young=false
    if [[ "$age" =~ ^[0-9]+$ ]]; then
        age_str="${age} days"
        if [[ $age -lt $MIN_PACKAGE_AGE_DAYS ]]; then
            is_young=true
            YOUNG_PACKAGES+=("$pkg_name")
        fi
    else
        age_str="unknown"
    fi
    
    # Format Output
    if [[ "$is_crit" == true ]]; then
        status_str="${RED}CRITICAL${NC}"
    fi
    
    if [[ "$is_young" == true ]]; then
        if [[ -n "$status_str" ]]; then status_str+=", "; fi
        status_str+="${YELLOW}FRESH${NC}"
    elif [[ -z "$status_str" ]]; then
         status_str="${GREEN}OK${NC}"
    fi

    printf "%-30s %-25s %-15s %b\n" "$pkg_name" "${version_info:0:24}" "$age_str" "$status_str"

done <<< "$UPDATES"

if [[ ${#CRITICAL_UPDATES[@]} -gt 0 ]]; then
    echo -e "\n${RED}⚠ WARNING: ${#CRITICAL_UPDATES[@]} critical package(s) will be updated${NC}"
    if [[ "$REBOOT_NEEDED" == true ]]; then
        echo -e "${RED}⚠ REBOOT WILL BE REQUIRED after update${NC}"
    fi
else
    echo -e "\n${GREEN}✓ No critical packages in this update${NC}"
fi

if [[ ${#YOUNG_PACKAGES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}found ${#YOUNG_PACKAGES[@]} recently updated (fresh) package(s)${NC}"
else
    echo -e "${GREEN}✓ All packages are at least $MIN_PACKAGE_AGE_DAYS days old${NC}"
fi

# Step 6: Show recommendations
echo -e "\n${YELLOW}[6/7] Update Recommendations${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ${#YOUNG_PACKAGES[@]} -gt 0 ]] || [[ ${#CRITICAL_UPDATES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}⚠ CAUTIOUS APPROACH RECOMMENDED${NC}"
    echo ""
    echo "Options:"
    echo "  1) Update everything (ignore warnings)"
    echo "  2) Exclude fresh packages (< ${MIN_PACKAGE_AGE_DAYS}d old)"
    echo "  3) Exclude critical packages"
    echo "  4) Cancel and wait"
    echo ""
    read -p "Choose option (1-4): " -n 1 -r choice
    echo ""
    
    case $choice in
        1)
            EXCLUDE_PKGS=""
            ;;
        2)
            EXCLUDE_PKGS=$(printf " --ignore %s" "${YOUNG_PACKAGES[@]}")
            echo -e "${BLUE}Will exclude: ${YOUNG_PACKAGES[*]}${NC}"
            ;;
        3)
            EXCLUDE_PKGS=$(printf " --ignore %s" "${CRITICAL_UPDATES[@]}")
            echo -e "${BLUE}Will exclude: ${CRITICAL_UPDATES[*]}${NC}"
            ;;
        4)
            echo -e "${GREEN}Wise choice! Check back in a few days.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Cancelling.${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${GREEN}✓ All updates look safe!${NC}"
    EXCLUDE_PKGS=""
fi

# Step 7: Perform update
echo -e "\n${YELLOW}[7/7] Performing System Update${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -p "Ready to update? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Update cancelled.${NC}"
    exit 0
fi

echo "Running: sudo pacman -Syu $EXCLUDE_PKGS"
sudo pacman -Syu $EXCLUDE_PKGS

if [[ $? -eq 0 ]]; then
    echo -e "\n${GREEN}✓ Update completed successfully!${NC}"
    
    # Check for .pacnew files
    echo -e "\n${YELLOW}Checking for .pacnew files...${NC}"
    PACNEW_FILES=$(find /etc -name "*.pacnew" 2>/dev/null)
    
    if [[ -n "$PACNEW_FILES" ]]; then
        echo -e "${YELLOW}⚠ Found .pacnew files that need attention:${NC}"
        echo "$PACNEW_FILES"
        echo -e "\nRun 'sudo pacdiff' to merge them"
    else
        echo -e "${GREEN}✓ No .pacnew files found${NC}"
    fi
    
    # Check orphaned packages
    echo -e "\n${YELLOW}Checking for orphaned packages...${NC}"
    ORPHANS=$(pacman -Qtdq 2>/dev/null)
    
    if [[ -n "$ORPHANS" ]]; then
        echo -e "${YELLOW}⚠ Found orphaned packages:${NC}"
        echo "$ORPHANS"
        read -p "Remove them? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo pacman -Rns $(pacman -Qtdq)
        fi
    else
        echo -e "${GREEN}✓ No orphaned packages${NC}"
    fi
    
    if [[ "$REBOOT_NEEDED" == true ]]; then
        echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}    ⚠ REBOOT REQUIRED ⚠${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "Reboot now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo reboot
        fi
    fi
else
    echo -e "\n${RED}✗ Update failed!${NC}"
    echo "Your system is unchanged thanks to the snapshot."
    echo "To restore: sudo snapper -c root rollback"
    echo "Or list snapshots: sudo snapper -c root list"
    exit 1
fi

echo -e "\n${GREEN}All done! 🎉${NC}"
