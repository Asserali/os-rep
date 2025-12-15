#!/bin/bash
# =================================================================
# Alert Manager - Monitor metrics and trigger alerts
# =================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# =================================================================
# Configuration
# =================================================================

THRESHOLD_CONFIG="${PROJECT_ROOT}/config/alert_thresholds.conf"
ALERT_DIR="${PROJECT_ROOT}/data/alerts"
ALERT_LOG="${ALERT_DIR}/alerts.log"

# Load thresholds
if [ -f "$THRESHOLD_CONFIG" ]; then
    source "$THRESHOLD_CONFIG"
else
    log_warn "Alert thresholds configuration not found"
fi

ensure_directory "$ALERT_DIR"

# =================================================================
# Alert Functions
# =================================================================

send_alert() {
    local severity="$1"
    local component="$2"
    local message="$3"
    local value="$4"
    
    local timestamp=$(get_iso_timestamp)
    local alert_entry="[${timestamp}] [${severity}] ${component}: ${message} (value: ${value})"
    
    # Log to file
    echo "$alert_entry" >> "$ALERT_LOG"
    
    # Log to console
    case "$severity" in
        CRITICAL)
            log_error "$component: $message (value: $value)"
            ;;
        WARNING)
            log_warn "$component: $message (value: $value)"
            ;;
        *)
            log_info "$component: $message (value: $value)"
            ;;
    esac
    
    # Send desktop notification (if available)
    send_desktop_notification "$severity" "$component" "$message"
}

send_desktop_notification() {
    local severity="$1"
    local component="$2"
    local message="$3"
    
    local platform=$(detect_platform)
    
    case "$platform" in
        linux)
            if check_command "notify-send"; then
                notify-send -u critical "System Monitor Alert [$severity]" "$component: $message" 2>/dev/null
            fi
            ;;
        macos)
            if check_command "osascript"; then
                osascript -e "display notification \"$component: $message\" with title \"System Monitor [$severity]\"" 2>/dev/null
            fi
            ;;
        windows)
            # Windows notifications would require PowerShell
            ;;
    esac
}

# =================================================================
# Metric Checking Functions
# =================================================================

check_cpu_metrics() {
    local cpu_usage=$(echo "$1" | python3 -c "import sys, json; print(json.load(sys.stdin)['cpu']['usage_percent'])" 2>/dev/null)
    local cpu_temp=$(echo "$1" | python3 -c "import sys, json; print(json.load(sys.stdin)['cpu']['temperature_celsius'])" 2>/dev/null)
    
    # Check CPU usage
    if is_number "$cpu_usage"; then
        local status=$(check_threshold "$cpu_usage" "$CPU_USAGE_WARNING" "$CPU_USAGE_CRITICAL")
        if [ "$status" = "CRITICAL" ]; then
            send_alert "CRITICAL" "CPU" "CPU usage critical" "${cpu_usage}%"
        elif [ "$status" = "WARNING" ]; then
            send_alert "WARNING" "CPU" "CPU usage high" "${cpu_usage}%"
        fi
    fi
    
    # Check CPU temperature
    if is_number "$cpu_temp"; then
        local status=$(check_threshold "$cpu_temp" "$CPU_TEMP_WARNING" "$CPU_TEMP_CRITICAL")
        if [ "$status" = "CRITICAL" ]; then
            send_alert "CRITICAL" "CPU" "CPU temperature critical" "${cpu_temp}°C"
        elif [ "$status" = "WARNING" ]; then
            send_alert "WARNING" "CPU" "CPU temperature high" "${cpu_temp}°C"
        fi
    fi
}

check_memory_metrics() {
    local mem_usage=$(echo "$1" | python3 -c "import sys, json; print(json.load(sys.stdin)['memory']['usage_percent'])" 2>/dev/null)
    local swap_usage=$(echo "$1" | python3 -c "import sys, json; print(json.load(sys.stdin)['memory']['swap_usage_percent'])" 2>/dev/null)
    
    # Check memory usage
    if is_number "$mem_usage"; then
        local status=$(check_threshold "$mem_usage" "$MEMORY_USAGE_WARNING" "$MEMORY_USAGE_CRITICAL")
        if [ "$status" = "CRITICAL" ]; then
            send_alert "CRITICAL" "Memory" "Memory usage critical" "${mem_usage}%"
        elif [ "$status" = "WARNING" ]; then
            send_alert "WARNING" "Memory" "Memory usage high" "${mem_usage}%"
        fi
    fi
    
    # Check swap usage
    if is_number "$swap_usage"; then
        local status=$(check_threshold "$swap_usage" "$SWAP_USAGE_WARNING" "$SWAP_USAGE_CRITICAL")
        if [ "$status" = "CRITICAL" ]; then
            send_alert "CRITICAL" "Swap" "Swap usage critical" "${swap_usage}%"
        elif [ "$status" = "WARNING" ]; then
            send_alert "WARNING" "Swap" "Swap usage high" "${swap_usage}%"
        fi
    fi
}

check_disk_metrics() {
    # Extract filesystems array and check each
    local filesystems=$(echo "$1" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for fs in data['disk']['filesystems']:
    print(f\"{fs['mount']}|{fs['usage_percent']}\")
" 2>/dev/null)
    
    while IFS='|' read -r mount usage; do
        if is_number "$usage"; then
            local status=$(check_threshold "$usage" "$DISK_USAGE_WARNING" "$DISK_USAGE_CRITICAL")
            if [ "$status" = "CRITICAL" ]; then
                send_alert "CRITICAL" "Disk" "Disk usage critical on $mount" "${usage}%"
            elif [ "$status" = "WARNING" ]; then
                send_alert "WARNING" "Disk" "Disk usage high on $mount" "${usage}%"
            fi
        fi
    done <<< "$filesystems"
}

check_system_load() {
    local load1=$(echo "$1" | python3 -c "import sys, json; print(json.load(sys.stdin)['system_load']['load_average']['1min'])" 2>/dev/null)
    local cpu_count=$(echo "$1" | python3 -c "import sys, json; print(json.load(sys.stdin)['cpu']['core_count'])" 2>/dev/null)
    
    if is_number "$load1" && is_number "$cpu_count" && [ "$cpu_count" -gt 0 ]; then
        local normalized_load=$(awk "BEGIN {printf \"%.2f\", $load1 / $cpu_count}")
        local status=$(check_threshold "$normalized_load" "$LOAD_WARNING" "$LOAD_CRITICAL")
        
        if [ "$status" = "CRITICAL" ]; then
            send_alert "CRITICAL" "System Load" "System load critical" "${load1} (normalized: ${normalized_load})"
        elif [ "$status" = "WARNING" ]; then
            send_alert "WARNING" "System Load" "System load high" "${load1} (normalized: ${normalized_load})"
        fi
    fi
}

check_gpu_metrics() {
    local gpu_usage=$(echo "$1" | python3 -c "import sys, json; print(json.load(sys.stdin)['gpu']['gpu']['utilization_percent'])" 2>/dev/null)
    local gpu_temp=$(echo "$1" | python3 -c "import sys, json; print(json.load(sys.stdin)['gpu']['gpu']['temperature_celsius'])" 2>/dev/null)
    local gpu_mem=$(echo "$1" | python3 -c "import sys, json; print(json.load(sys.stdin)['gpu']['gpu']['memory_percent'])" 2>/dev/null)
    
    # Check GPU usage
    if is_number "$gpu_usage" && [ "$gpu_usage" != "0" ]; then
        local status=$(check_threshold "$gpu_usage" "$GPU_USAGE_WARNING" "$GPU_USAGE_CRITICAL")
        if [ "$status" = "CRITICAL" ]; then
            send_alert "CRITICAL" "GPU" "GPU utilization critical" "${gpu_usage}%"
        elif [ "$status" = "WARNING" ]; then
            send_alert "WARNING" "GPU" "GPU utilization high" "${gpu_usage}%"
        fi
    fi
    
    # Check GPU temperature
    if is_number "$gpu_temp" && [ "$gpu_temp" != "0" ]; then
        local status=$(check_threshold "$gpu_temp" "$GPU_TEMP_WARNING" "$GPU_TEMP_CRITICAL")
        if [ "$status" = "CRITICAL" ]; then
            send_alert "CRITICAL" "GPU" "GPU temperature critical" "${gpu_temp}°C"
        elif [ "$status" = "WARNING" ]; then
            send_alert "WARNING" "GPU" "GPU temperature high" "${gpu_temp}°C"
        fi
    fi
}

# =================================================================
# Main Alert Processing
# =================================================================

process_alerts() {
    # Read JSON from stdin
    local metrics=$(cat)
    
    if ! is_valid_json "$metrics"; then
        log_error "Invalid JSON input to alert manager"
        return 1
    fi
    
    log_debug "Processing alerts..."
    
    # Check each component
    check_cpu_metrics "$metrics"
    check_memory_metrics "$metrics"
    check_disk_metrics "$metrics"
    check_system_load "$metrics"
    check_gpu_metrics "$metrics"
}

# =================================================================
# Entry Point
# =================================================================

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    process_alerts
fi
