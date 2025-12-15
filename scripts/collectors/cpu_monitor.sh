#!/bin/bash
# =================================================================
# CPU Monitor - Cross-platform CPU usage and temperature monitoring
# =================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# =================================================================
# CPU Usage Monitoring
# =================================================================

get_cpu_usage_linux() {
    # Read /proc/stat for CPU usage
    local cpu_line=$(grep '^cpu ' /proc/stat)
    local cpu_times=($cpu_line)
    
    local idle=${cpu_times[4]}
    local total=0
    for value in "${cpu_times[@]:1}"; do
        total=$((total + value))
    done
    
    # Calculate percentage
    if [ -f /tmp/cpu_prev_total ]; then
        local prev_total=$(cat /tmp/cpu_prev_total)
        local prev_idle=$(cat /tmp/cpu_prev_idle)
        
        local diff_total=$((total - prev_total))
        local diff_idle=$((idle - prev_idle))
        
        if [ $diff_total -gt 0 ]; then
            local usage=$(awk "BEGIN {printf \"%.2f\", 100 * ($diff_total - $diff_idle) / $diff_total}")
            echo "$usage"
        else
            echo "0.00"
        fi
    else
        echo "0.00"
    fi
    
    # Store current values
    echo "$total" > /tmp/cpu_prev_total
    echo "$idle" > /tmp/cpu_prev_idle
}

get_cpu_usage_macos() {
    # Use top command on macOS
    local cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    echo "$cpu_usage"
}

get_cpu_usage_windows() {
    # Use wmic on Windows (in WSL/Git Bash)
    local cpu_usage=$(wmic cpu get loadpercentage | grep -o '[0-9]\+' | head -1)
    echo "${cpu_usage:-0}"
}

get_cpu_usage() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_cpu_usage_linux
            ;;
        macos)
            get_cpu_usage_macos
            ;;
        windows)
            get_cpu_usage_windows
            ;;
        *)
            echo "0.00"
            ;;
    esac
}

# =================================================================
# CPU Temperature Monitoring
# =================================================================

get_cpu_temp_linux() {
    local temp=""
    
    # Try lm-sensors first
    if check_command "sensors"; then
        temp=$(sensors | grep -i "core 0" | awk '{print $3}' | sed 's/+//;s/°C//' | head -1)
    fi
    
    # Fallback to thermal zone
    if [ -z "$temp" ] && [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        local temp_millidegrees=$(cat /sys/class/thermal/thermal_zone0/temp)
        temp=$(awk "BEGIN {printf \"%.1f\", $temp_millidegrees / 1000}")
    fi
    
    echo "${temp:-N/A}"
}

get_cpu_temp_macos() {
    # macOS requires additional tools like osx-cpu-temp
    if check_command "osx-cpu-temp"; then
        osx-cpu-temp | grep -o '[0-9.]\+' | head -1
    else
        echo "N/A"
    fi
}

get_cpu_temp_windows() {
    # Windows temperature monitoring is complex, typically requires admin rights
    echo "N/A"
}

get_cpu_temp() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_cpu_temp_linux
            ;;
        macos)
            get_cpu_temp_macos
            ;;
        windows)
            get_cpu_temp_windows
            ;;
        *)
            echo "N/A"
            ;;
    esac
}

# =================================================================
# CPU Information
# =================================================================

get_cpu_count() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            nproc 2>/dev/null || grep -c processor /proc/cpuinfo
            ;;
        macos)
            sysctl -n hw.ncpu
            ;;
        windows)
            echo "$NUMBER_OF_PROCESSORS"
            ;;
        *)
            echo "1"
            ;;
    esac
}

get_cpu_model() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs
            ;;
        macos)
            sysctl -n machdep.cpu.brand_string
            ;;
        windows)
            wmic cpu get name | grep -v Name | head -1 | xargs
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

get_cpu_frequency() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq" ]; then
                local freq_khz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
                awk "BEGIN {printf \"%.2f\", $freq_khz / 1000000}"
            else
                lscpu | grep "CPU MHz" | awk '{print $3/1000}' | head -1
            fi
            ;;
        macos)
            sysctl -n hw.cpufrequency | awk '{printf "%.2f", $1/1000000000}'
            ;;
        windows)
            wmic cpu get CurrentClockSpeed | grep -o '[0-9]\+' | head -1 | awk '{printf "%.2f", $1/1000}'
            ;;
        *)
            echo "0.00"
            ;;
    esac
}

# =================================================================
# Main Function - Output JSON
# =================================================================

collect_cpu_metrics() {
    local cpu_usage=$(get_cpu_usage)
    local cpu_temp=$(get_cpu_temp)
    local cpu_count=$(get_cpu_count)
    local cpu_model=$(get_cpu_model)
    local cpu_freq=$(get_cpu_frequency)
    
    cat <<EOF
{
  "usage_percent": $cpu_usage,
  "temperature_celsius": "$cpu_temp",
  "core_count": $cpu_count,
  "model": "$cpu_model",
  "frequency_ghz": $cpu_freq,
  "timestamp": "$(get_iso_timestamp)"
}
EOF
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    collect_cpu_metrics
fi
