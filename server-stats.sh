#!/bin/bash

###############################################################################
# Server Stats Analysis Script
# This script analyzes basic server performance metrics on any Linux server
# Usage: ./server-stats.sh
###############################################################################

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to print colored percentage
print_percentage() {
    local percent=$1
    if (( $(echo "$percent >= 80" | bc -l) )); then
        echo -e "${RED}$percent%${NC}"
    elif (( $(echo "$percent >= 50" | bc -l) )); then
        echo -e "${YELLOW}$percent%${NC}"
    else
        echo -e "${GREEN}$percent%${NC}"
    fi
}

###############################################################################
# TOTAL CPU USAGE
###############################################################################
print_header "CPU USAGE"

# Get CPU usage using top command
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d'%' -f1)

if [ -z "$cpu_usage" ]; then
    # Fallback method using /proc/stat if top doesn't work
    cpu_usage=$(awk '/^cpu / {usage=($2+$4)*100/($2+$4+$5)} END {print usage}' /proc/stat)
fi

echo -e "Current CPU Usage: $(print_percentage ${cpu_usage%.*})"

# Additional CPU info
echo -e "\nCPU Details:"
echo "- Number of CPUs: $(nproc)"
echo "- CPU Model: $(grep -m1 'model name' /proc/cpuinfo | cut -d':' -f2 | xargs)"
echo "- Load Average (1m, 5m, 15m): $(uptime | grep -o 'load average.*' | cut -d':' -f2 | xargs)"

###############################################################################
# TOTAL MEMORY USAGE
###############################################################################
print_header "MEMORY USAGE"

mem_info=$(free -b | grep Mem:)
mem_total=$(echo $mem_info | awk '{print $2}')
mem_used=$(echo $mem_info | awk '{print $3}')
mem_free=$(echo $mem_info | awk '{print $4}')
mem_percent=$((mem_used * 100 / mem_total))

# Convert to human-readable format
mem_total_gb=$(echo "scale=2; $mem_total / 1024 / 1024 / 1024" | bc)
mem_used_gb=$(echo "scale=2; $mem_used / 1024 / 1024 / 1024" | bc)
mem_free_gb=$(echo "scale=2; $mem_free / 1024 / 1024 / 1024" | bc)

echo -e "Total Memory: ${BLUE}${mem_total_gb} GB${NC}"
echo -e "Used Memory: ${RED}${mem_used_gb} GB${NC} ($(print_percentage $mem_percent))"
echo -e "Free Memory: ${GREEN}${mem_free_gb} GB${NC}"

# Buffer/Cache info
cache_info=$(free -b | grep Buffers)
buffers=$(echo $cache_info | awk '{print $3}')
cache=$(echo $cache_info | awk '{print $4}')

if [ ! -z "$cache" ]; then
    buffers_gb=$(echo "scale=2; $buffers / 1024 / 1024 / 1024" | bc)
    cache_gb=$(echo "scale=2; $cache / 1024 / 1024 / 1024" | bc)
    echo -e "Buffers: ${buffers_gb} GB"
    echo -e "Cached: ${cache_gb} GB"
fi

###############################################################################
# TOTAL DISK USAGE
###############################################################################
print_header "DISK USAGE"

# Get disk usage for root filesystem and all mounted filesystems
df -h | tail -n +2 | while read line; do
    filesystem=$(echo $line | awk '{print $1}')
    size=$(echo $line | awk '{print $2}')
    used=$(echo $line | awk '{print $3}')
    avail=$(echo $line | awk '{print $4}')
    percent=$(echo $line | awk '{print $5}' | cut -d'%' -f1)
    mount=$(echo $line | awk '{print $6}')
    
    echo -e "Filesystem: ${BLUE}$filesystem${NC} (mounted at $mount)"
    echo "  Size: $size | Used: $used | Available: $avail | Usage: $(print_percentage $percent)"
done

###############################################################################
# TOP 5 PROCESSES BY CPU USAGE
###############################################################################
print_header "TOP 5 PROCESSES BY CPU USAGE"

echo "PID     CPU%    MEM%    COMMAND"
echo "---     ----    ----    -------"

ps aux --sort=-%cpu | head -n 6 | tail -n 5 | awk '{printf "%-7s %-7s %-7s %s\n", $2, $3, $4, $11}'

###############################################################################
# TOP 5 PROCESSES BY MEMORY USAGE
###############################################################################
print_header "TOP 5 PROCESSES BY MEMORY USAGE"

echo "PID     MEM%    CPU%    COMMAND"
echo "---     ----    ----    -------"

ps aux --sort=-%mem | head -n 6 | tail -n 5 | awk '{printf "%-7s %-7s %-7s %s\n", $2, $4, $3, $11}'

###############################################################################
# Summary
###############################################################################
print_header "SUMMARY"

echo -e "Script execution completed at: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "Hostname: $(hostname)"
echo -e "Uptime: $(uptime -p 2>/dev/null || uptime | cut -d',' -f1)"
echo -e "Kernel: $(uname -r)"
