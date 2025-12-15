#!/bin/bash
# =================================================================
# System Load Monitor - Cross-platform system load metrics
# =================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# =================================================================
# System Load Average
# =================================================================

get_load_average_linux() {
    if [ -f /proc/loadavg ]; then
        local loadavg=$(cat /proc/loadavg)
        local load1=$(echo "$loadavg" | awk '{print $1}')
        local load5=$(echo "$loadavg" | awk '{print $2}')
        local load15=$(echo "$loadavg" | awk '{print $3}')
        echo "$load1|$load5|$load15"
    else
        echo "0.00|0.00|0.00"
    fi
}

get_load_average_macos() {
    local loadavg=$(sysctl -n vm.loadavg | tr -d '{}')
    local load1=$(echo "$loadavg" | awk '{print $1}')
    local load5=$(echo "$loadavg" | awk '{print $2}')
    local load15=$(echo "$loadavg" | awk '{print $3}')
    echo "$load1|$load5|$load15"
}

get_load_average_windows() {
    # Windows doesn't have load average concept, approximate with CPU queue length
    echo "0.00|0.00|0.00"
}

get_load_average() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_load_average_linux
            ;;
        macos)
            get_load_average_macos
            ;;
        windows)
            get_load_average_windows
            ;;
        *)
            echo "0.00|0.00|0.00"
            ;;
    esac
}

# =================================================================
# Process Count
# =================================================================

get_process_count_linux() {
    ps aux | wc -l
}

get_process_count_macos() {
    ps aux | wc -l
}

get_process_count_windows() {
    tasklist | wc -l
}

get_process_count() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_process_count_linux
            ;;
        macos)
            get_process_count_macos
            ;;
        windows)
            get_process_count_windows
            ;;
        *)
            echo "0"
            ;;
    esac
}

# =================================================================
# Running/Sleeping Process Count
# =================================================================

get_process_states_linux() {
    local running=$(ps aux | awk '$8 == "R" || $8 ~ /^R/ {print}' | wc -l)
    local sleeping=$(ps aux | awk '$8 == "S" || $8 ~ /^S/ {print}' | wc -l)
    local zombie=$(ps aux | awk '$8 == "Z" || $8 ~ /^Z/ {print}' | wc -l)
    echo "$running|$sleeping|$zombie"
}

get_process_states_macos() {
    local running=$(ps aux | awk '$8 == "R" || $8 ~ /^R/ {print}' | wc -l)
    local sleeping=$(ps aux | awk '$8 == "S" || $8 ~ /^S/ {print}' | wc -l)
    local zombie=$(ps aux | awk '$8 == "Z" || $8 ~ /^Z/ {print}' | wc -l)
    echo "$running|$sleeping|$zombie"
}

get_process_states_windows() {
    echo "0|0|0"
}

get_process_states() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_process_states_linux
            ;;
        macos)
            get_process_states_macos
            ;;
        windows)
            get_process_states_windows
            ;;
        *)
            echo "0|0|0"
            ;;
    esac
}

# =================================================================
# Top Processes by CPU
# =================================================================

get_top_cpu_processes() {
    local platform=$(detect_platform)
    local count=5
    
    case "$platform" in
        linux|macos)
            ps aux --sort=-%cpu | head -n $((count + 1)) | tail -n +2 | awk '{
                printf "{\"pid\":%d,\"user\":\"%s\",\"cpu\":%.2f,\"mem\":%.2f,\"command\":\"%s\"},",
                $2, $1, $3, $4, $11
            }' | sed 's/,$//'
            ;;
        windows)
            echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}

# =================================================================
# Main Function - Output JSON
# =================================================================

collect_system_load_metrics() {
    local load_avg=$(get_load_average)
    local load1=$(echo "$load_avg" | cut -d'|' -f1)
    local load5=$(echo "$load_avg" | cut -d'|' -f2)
    local load15=$(echo "$load_avg" | cut -d'|' -f3)
    
    local process_count=$(get_process_count)
    
    local process_states=$(get_process_states)
    local running=$(echo "$process_states" | cut -d'|' -f1)
    local sleeping=$(echo "$process_states" | cut -d'|' -f2)
    local zombie=$(echo "$process_states" | cut -d'|' -f3)
    
    local top_processes=$(get_top_cpu_processes)
    
    cat <<EOF
{
  "load_average": {
    "1min": $load1,
    "5min": $load5,
    "15min": $load15
  },
  "total_processes": $process_count,
  "running_processes": $running,
  "sleeping_processes": $sleeping,
  "zombie_processes": $zombie,
  "top_cpu_processes": [$top_processes],
  "timestamp": "$(get_iso_timestamp)"
}
EOF
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    collect_system_load_metrics
fi
