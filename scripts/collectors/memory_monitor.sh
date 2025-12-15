#!/bin/bash
# =================================================================
# Memory Monitor - Cross-platform memory usage monitoring
# =================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# =================================================================
# Memory Usage Monitoring
# =================================================================

get_memory_linux() {
    if [ -f /proc/meminfo ]; then
        local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        local mem_free=$(grep MemFree /proc/meminfo | awk '{print $2}')
        local buffers=$(grep Buffers /proc/meminfo | awk '{print $2}')
        local cached=$(grep "^Cached:" /proc/meminfo | awk '{print $2}')
        
        local mem_used=$((mem_total - mem_available))
        local mem_usage_percent=$(awk "BEGIN {printf \"%.2f\", ($mem_used / $mem_total) * 100}")
        
        # Convert KB to bytes
        mem_total=$((mem_total * 1024))
        mem_used=$((mem_used * 1024))
        mem_available=$((mem_available * 1024))
        
        echo "$mem_total|$mem_used|$mem_available|$mem_usage_percent"
    else
        echo "0|0|0|0.00"
    fi
}

get_memory_macos() {
    local page_size=$(pagesize)
    local mem_stats=$(vm_stat)
    
    local pages_free=$(echo "$mem_stats" | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    local pages_active=$(echo "$mem_stats" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    local pages_inactive=$(echo "$mem_stats" | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
    local pages_wired=$(echo "$mem_stats" | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
    
    local mem_total=$(sysctl -n hw.memsize)
    local mem_used=$(( (pages_active + pages_inactive + pages_wired) * page_size ))
    local mem_available=$(( pages_free * page_size ))
    local mem_usage_percent=$(awk "BEGIN {printf \"%.2f\", ($mem_used / $mem_total) * 100}")
    
    echo "$mem_total|$mem_used|$mem_available|$mem_usage_percent"
}

get_memory_windows() {
    # Use wmic on Windows
    local mem_info=$(wmic OS get TotalVisibleMemorySize,FreePhysicalMemory /format:list | grep "=")
    local mem_total_kb=$(echo "$mem_info" | grep TotalVisibleMemorySize | cut -d'=' -f2 | tr -d '\r')
    local mem_free_kb=$(echo "$mem_info" | grep FreePhysicalMemory | cut -d'=' -f2 | tr -d '\r')
    
    local mem_total=$((mem_total_kb * 1024))
    local mem_available=$((mem_free_kb * 1024))
    local mem_used=$((mem_total - mem_available))
    local mem_usage_percent=$(awk "BEGIN {printf \"%.2f\", ($mem_used / $mem_total) * 100}")
    
    echo "$mem_total|$mem_used|$mem_available|$mem_usage_percent"
}

get_memory_info() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_memory_linux
            ;;
        macos)
            get_memory_macos
            ;;
        windows)
            get_memory_windows
            ;;
        *)
            echo "0|0|0|0.00"
            ;;
    esac
}

# =================================================================
# Swap Usage Monitoring
# =================================================================

get_swap_linux() {
    if [ -f /proc/meminfo ]; then
        local swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
        local swap_free=$(grep SwapFree /proc/meminfo | awk '{print $2}')
        
        if [ "$swap_total" -eq 0 ]; then
            echo "0|0|0.00"
        else
            local swap_used=$((swap_total - swap_free))
            local swap_usage_percent=$(awk "BEGIN {printf \"%.2f\", ($swap_used / $swap_total) * 100}")
            
            # Convert KB to bytes
            swap_total=$((swap_total * 1024))
            swap_used=$((swap_used * 1024))
            
            echo "$swap_total|$swap_used|$swap_usage_percent"
        fi
    else
        echo "0|0|0.00"
    fi
}

get_swap_macos() {
    local swap_info=$(sysctl vm.swapusage | cut -d'=' -f2)
    
    if echo "$swap_info" | grep -q "total = 0"; then
        echo "0|0|0.00"
    else
        local swap_total=$(echo "$swap_info" | grep -o 'total = [0-9.]*[MG]' | grep -o '[0-9.]*[MG]')
        local swap_used=$(echo "$swap_info" | grep -o 'used = [0-9.]*[MG]' | grep -o '[0-9.]*[MG]')
        
        # Convert to bytes (basic conversion)
        swap_total=$(echo "$swap_total" | sed 's/M/*1048576/;s/G/*1073741824/' | bc)
        swap_used=$(echo "$swap_used" | sed 's/M/*1048576/;s/G/*1073741824/' | bc)
        
        local swap_usage_percent=$(awk "BEGIN {printf \"%.2f\", ($swap_used / $swap_total) * 100}")
        
        echo "$swap_total|$swap_used|$swap_usage_percent"
    fi
}

get_swap_windows() {
    # Windows pagefile information
    local pagefile_info=$(wmic pagefile get AllocatedBaseSize,CurrentUsage /format:list | grep "=")
    local pagefile_total=$(echo "$pagefile_info" | grep AllocatedBaseSize | cut -d'=' -f2 | tr -d '\r')
    local pagefile_used=$(echo "$pagefile_info" | grep CurrentUsage | cut -d'=' -f2 | tr -d '\r')
    
    if [ -z "$pagefile_total" ] || [ "$pagefile_total" -eq 0 ]; then
        echo "0|0|0.00"
    else
        # Values are in MB
        pagefile_total=$((pagefile_total * 1048576))
        pagefile_used=$((pagefile_used * 1048576))
        
        local swap_usage_percent=$(awk "BEGIN {printf \"%.2f\", ($pagefile_used / $pagefile_total) * 100}")
        
        echo "$pagefile_total|$pagefile_used|$swap_usage_percent"
    fi
}

get_swap_info() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_swap_linux
            ;;
        macos)
            get_swap_macos
            ;;
        windows)
            get_swap_windows
            ;;
        *)
            echo "0|0|0.00"
            ;;
    esac
}

# =================================================================
# Main Function - Output JSON
# =================================================================

collect_memory_metrics() {
    local mem_info=$(get_memory_info)
    local mem_total=$(echo "$mem_info" | cut -d'|' -f1)
    local mem_used=$(echo "$mem_info" | cut -d'|' -f2)
    local mem_available=$(echo "$mem_info" | cut -d'|' -f3)
    local mem_usage_percent=$(echo "$mem_info" | cut -d'|' -f4)
    
    local swap_info=$(get_swap_info)
    local swap_total=$(echo "$swap_info" | cut -d'|' -f1)
    local swap_used=$(echo "$swap_info" | cut -d'|' -f2)
    local swap_usage_percent=$(echo "$swap_info" | cut -d'|' -f3)
    
    cat <<EOF
{
  "total_bytes": $mem_total,
  "used_bytes": $mem_used,
  "available_bytes": $mem_available,
  "usage_percent": $mem_usage_percent,
  "swap_total_bytes": $swap_total,
  "swap_used_bytes": $swap_used,
  "swap_usage_percent": $swap_usage_percent,
  "timestamp": "$(get_iso_timestamp)"
}
EOF
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    collect_memory_metrics
fi
