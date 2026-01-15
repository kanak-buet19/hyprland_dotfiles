#!/bin/bash

# Get all occupied workspace IDs
occupied=$(hyprctl workspaces -j | jq '.[].id' | sort -n)

# Find first empty workspace
next=1
while echo "$occupied" | grep -q "^${next}$"; do
    ((next++))
done

# Move to that workspace
hyprctl dispatch workspace $next