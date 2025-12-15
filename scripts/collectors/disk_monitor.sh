#!/bin/bash
# =================================================================
# Disk Monitor - Cross-platform disk usage and SMART status
# =================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# =================================================================
# Disk Usage Monitoring
# =================================================================

get_disk_usage_linux() {
    df -B1 | grep -vE '^Filesystem|tmpfs|cdrom|loop' | awk '{
        printf "{\"device\":\"%s\",\"mount\":\"%s\",\"total\":%s,\"used\":%s,\"available\":%s,\"usage_percent\":%.2f},",
        $1, $6, $2, $3, $4, ($3/$2)*100
    }' | sed 's/,$//'
}

get_disk_usage_macos() {
    df -k | grep -vE '^Filesystem|devfs|map' | awk '{
        total=$2*1024; used=$3*1024; avail=$4*1024;
        printf "{\"device\":\"%s\",\"mount\":\"%s\",\"total\":%d,\"used\":%d,\"available\":%d,\"usage_percent\":%.2f},",
        $1, $9, total, used, avail, (used/total)*100
    }' | sed 's/,$//'
}

get_disk_usage_windows() {
    wmic logicaldisk get DeviceID,Size,FreeSpace /format:csv | grep -v '^$' | tail -n +2 | while IFS=',' read -r node device free size; do
        if [ -n "$size" ] && [ "$size" != "0" ]; then
            used=$((size - free))
            usage_percent=$(awk "BEGIN {printf \"%.2f\", ($used / $size) * 100}")
            echo "{\"device\":\"$device\",\"mount\":\"$device\\\\\",\"total\":$size,\"used\":$used,\"available\":$free,\"usage_percent\":$usage_percent},"
        fi
    done | sed 's/,$//'
}

get_disk_usage() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_disk_usage_linux
            ;;
        macos)
            get_disk_usage_macos
            ;;
        windows)
            get_disk_usage_windows
            ;;
        *)
            echo ""
            ;;
    esac
}

# =================================================================
# Disk I/O Statistics
# =================================================================

get_disk_io_linux() {
    if [ -f /proc/diskstats ]; then
        local main_disk=$(df / | tail -1 | awk '{print $1}' | sed 's|/dev/||;s|[0-9]*$||')
        local stats=$(grep -w "$main_disk" /proc/diskstats | head -1)
        
        local reads_completed=$(echo "$stats" | awk '{print $4}')
        local sectors_read=$(echo "$stats" | awk '{print $6}')
        local writes_completed=$(echo "$stats" | awk '{print $8}')
        local sectors_written=$(echo "$stats" | awk '{print $10}')
        
        # sectors are typically 512 bytes
        local bytes_read=$((sectors_read * 512))
        local bytes_written=$((sectors_written * 512))
        
        echo "$reads_completed|$writes_completed|$bytes_read|$bytes_written"
    else
        echo "0|0|0|0"
    fi
}

get_disk_io_macos() {
    if check_command "iostat"; then
        local stats=$(iostat -d | tail -1)
        echo "0|0|0|0"  # macOS I/O stats are complex, simplified for now
    else
        echo "0|0|0|0"
    fi
}

get_disk_io_windows() {
    # Windows disk I/O would require performance counters
    echo "0|0|0|0"
}

get_disk_io() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_disk_io_linux
            ;;
        macos)
            get_disk_io_macos
            ;;
        windows)
            get_disk_io_windows
            ;;
        *)
            echo "0|0|0|0"
            ;;
    esac
}

# =================================================================
# SMART Status
# =================================================================

get_smart_status_linux() {
    if ! check_command "smartctl"; then
        echo "\"Not Available (smartctl not installed)\""
        return
    fi
    
    local main_disk=$(df / | tail -1 | awk '{print $1}')
    local smart_status=$(sudo smartctl -H "$main_disk" 2>/dev/null | grep "SMART overall-health" | awk '{print $NF}')
    
    if [ -z "$smart_status" ]; then
        echo "\"N/A\""
    else
        echo "\"$smart_status\""
    fi
}

get_smart_status_macos() {
    if ! check_command "smartctl"; then
        echo "\"Not Available (smartctl not installed)\""
        return
    fi
    
    local main_disk=$(diskutil list | grep "internal" | head -1 | awk '{print $1}')
    local smart_status=$(sudo smartctl -H "$main_disk" 2>/dev/null | grep "SMART overall-health" | awk '{print $NF}')
    
    if [ -z "$smart_status" ]; then
        echo "\"N/A\""
    else
        echo "\"$smart_status\""
    fi
}

get_smart_status_windows() {
    # SMART on Windows requires admin rights and special tools
    echo "\"N/A\""
}

get_smart_status() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_smart_status_linux
            ;;
        macos)
            get_smart_status_macos
            ;;
        windows)
            get_smart_status_windows
            ;;
        *)
            echo "\"N/A\""
            ;;
    esac
}

# =================================================================
# Main Function - Output JSON
# =================================================================

collect_disk_metrics() {
    local disk_usage=$(get_disk_usage)
    local disk_io=$(get_disk_io)
    local smart_status=$(get_smart_status)
    
    local reads=$(echo "$disk_io" | cut -d'|' -f1)
    local writes=$(echo "$disk_io" | cut -d'|' -f2)
    local bytes_read=$(echo "$disk_io" | cut -d'|' -f3)
    local bytes_written=$(echo "$disk_io" | cut -d'|' -f4)
    
    cat <<EOF
{
  "filesystems": [$disk_usage],
  "io_stats": {
    "reads_completed": $reads,
    "writes_completed": $writes,
    "bytes_read": $bytes_read,
    "bytes_written": $bytes_written
  },
  "smart_status": $smart_status,
  "timestamp": "$(get_iso_timestamp)"
}
EOF
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    collect_disk_metrics
fi
