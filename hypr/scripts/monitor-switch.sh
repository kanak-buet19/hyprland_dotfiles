#!/bin/bash

# Monitor switch script for Hyprland
options="Both Monitors\nLaptop Only\nExternal Only\nMirror"

chosen=$(echo -e "$options" | rofi -dmenu -p "Display Mode")

case $chosen in
    "Both Monitors")
        hyprctl keyword monitor "eDP-2,1920x1080@60,0x0,1"
        hyprctl keyword monitor "HDMI-A-1,1920x1080@144,1920x0,1"
        ;;
    "Laptop Only")
        hyprctl keyword monitor "eDP-2,1920x1080@60,0x0,1"
        hyprctl keyword monitor "HDMI-A-1,disable"
        ;;
    "External Only")
        hyprctl keyword monitor "eDP-2,disable"
        hyprctl keyword monitor "HDMI-A-1,1920x1080@144,0x0,1"
        ;;
    "Mirror")
        hyprctl keyword monitor "HDMI-A-1,1920x1080@60,0x0,1,mirror,eDP-2"
        ;;
esac