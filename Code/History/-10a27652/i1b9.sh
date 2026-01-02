#!/bin/bash

# Get the active VS Code window's working directory
# This uses hyprctl to get the focused window's PID, then finds the cwd
vscode_pid=$(hyprctl activewindow -j | jq -r '.pid')

if [ -z "$vscode_pid" ]; then
    notify-send "No active VS Code window"
    exit 1
fi

# Get the working directory of VS Code
cwd=$(readlink -f /proc/$vscode_pid/cwd 2>/dev/null)

# Find PDF in current directory or build subdirectory
if [ -f "$cwd/main.pdf" ]; then
    zathura "$cwd/main.pdf" &
elif [ -f "$cwd/build/main.pdf" ]; then
    zathura "$cwd/build/main.pdf" &
else
    notify-send "No PDF found" "in $cwd"
fi