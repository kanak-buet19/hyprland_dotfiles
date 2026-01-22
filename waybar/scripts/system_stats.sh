#!/bin/bash

# Calculate CPU Usage
read cpu a b c previdle e f g h junk < /proc/stat
prevtotal=$((a+b+c+previdle+e+f+g+h))
sleep 0.5
read cpu a b c idle e f g h junk < /proc/stat
total=$((a+b+c+idle+e+f+g+h))
cpu_usage=$((100*( (total-prevtotal) - (idle-previdle) ) / (total-prevtotal) ))

# Get Memory Usage
mem_used=$(free -h | awk '/^Mem:/ {print $3}')
mem_total=$(free -h | awk '/^Mem:/ {print $2}')
mem_percent=$(free | awk '/^Mem:/ {printf("%.0f"), $3/$2 * 100}')

# Get Disk Usage
disk_used=$(df -h / | awk 'NR==2 {print $3}')
disk_total=$(df -h / | awk 'NR==2 {print $2}')
disk_percent=$(df / | awk 'NR==2 {print $5}')

# Output JSON
tooltip="CPU: ${cpu_usage}%\nRAM: ${mem_used} / ${mem_total} (${mem_percent}%)\nDisk: ${disk_used} / ${disk_total} (${disk_percent})"
echo "{\"text\": \"\", \"tooltip\": \"$tooltip\", \"class\": \"custom-system\"}"
