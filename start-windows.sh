#!/bin/bash

# Default values
DEFAULT_CPU=4
DEFAULT_RAM="8G"
DEFAULT_DISK="64G"

# Prompt for resources
echo "Configure Windows VM resources (press Enter for defaults):"
echo ""

read -p "CPU cores [default: $DEFAULT_CPU]: " CPU_CORES
CPU_CORES=${CPU_CORES:-$DEFAULT_CPU}

read -p "RAM size [default: $DEFAULT_RAM]: " RAM_SIZE
RAM_SIZE=${RAM_SIZE:-$DEFAULT_RAM}

read -p "Disk size [default: $DEFAULT_DISK]: " DISK_SIZE
DISK_SIZE=${DISK_SIZE:-$DEFAULT_DISK}

echo ""
echo "Starting with: CPU=$CPU_CORES, RAM=$RAM_SIZE, DISK=$DISK_SIZE"
echo ""

# Check if container is already running
if docker ps | grep -q windows; then
    echo "Windows container is already running."
    read -p "Reconnect to existing instance? (Y/n): " RECONNECT
    if [[ ! $RECONNECT =~ ^[Nn]$ ]]; then
        echo "Connecting via RDP..."
        xfreerdp3 /v:localhost:3389 /u:Docker /p:admin /cert:ignore /dynamic-resolution +clipboard
        exit 0
    else
        echo "Stopping existing container..."
        docker stop windows
        docker rm windows
    fi
fi

# Start container
echo "Starting Windows container..."
docker run -d --name windows \
  -e "VERSION=11" \
  -e "CPU_CORES=$CPU_CORES" \
  -e "RAM_SIZE=$RAM_SIZE" \
  -e "DISK_SIZE=$DISK_SIZE" \
  -p 8006:8006 \
  -p 3389:3389 \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add NET_ADMIN \
  -v "${HOME}/windows:/storage" \
  --stop-timeout 120 \
  docker.io/dockurr/windows

echo ""
echo "Waiting for Windows to boot..."
sleep 15

echo "Connecting via RDP..."
xfreerdp3 /v:localhost:3389 /u:Docker /p:admin /cert:ignore /dynamic-resolution +clipboard


# Auto cleanup after RDP disconnects
echo ""
echo "Stopping container..."
docker stop windows
docker rm windows
echo "Container stopped and removed."
