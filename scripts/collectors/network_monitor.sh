#!/bin/bash
# =================================================================
# Network Monitor - Cross-platform network interface statistics
# =================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# =================================================================
# Network Interface Statistics
# =================================================================

get_network_stats_linux() {
    if [ ! -f /proc/net/dev ]; then
        echo ""
        return
    fi
    
    tail -n +3 /proc/net/dev | while read -r line; do
        local interface=$(echo "$line" | awk -F: '{print $1}' | xargs)
        local stats=$(echo "$line" | awk -F: '{print $2}')
        
        # Skip loopback
        if [ "$interface" = "lo" ]; then
            continue
        fi
        
        local rx_bytes=$(echo "$stats" | awk '{print $1}')
        local rx_packets=$(echo "$stats" | awk '{print $2}')
        local rx_errors=$(echo "$stats" | awk '{print $3}')
        local tx_bytes=$(echo "$stats" | awk '{print $9}')
        local tx_packets=$(echo "$stats" | awk '{print $10}')
        local tx_errors=$(echo "$stats" | awk '{print $11}')
        
        echo "{\"interface\":\"$interface\",\"rx_bytes\":$rx_bytes,\"rx_packets\":$rx_packets,\"rx_errors\":$rx_errors,\"tx_bytes\":$tx_bytes,\"tx_packets\":$tx_packets,\"tx_errors\":$tx_errors},"
    done | sed 's/,$//'
}

get_network_stats_macos() {
    netstat -ib | grep -v "Name" | grep -v "lo0" | awk 'NF>=10 {
        printf "{\"interface\":\"%s\",\"rx_bytes\":%d,\"rx_packets\":%d,\"rx_errors\":%d,\"tx_bytes\":%d,\"tx_packets\":%d,\"tx_errors\":%d},",
        $1, $7, $5, $6, $10, $8, $9
    }' | sed 's/,$//'
}

get_network_stats_windows() {
    # Use netstat on Windows
    netstat -e | grep "Bytes" | awk '{
        printf "{\"interface\":\"eth0\",\"rx_bytes\":%d,\"rx_packets\":0,\"rx_errors\":0,\"tx_bytes\":%d,\"tx_packets\":0,\"tx_errors\":0}",
        $2, $3
    }'
}

get_network_stats() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_network_stats_linux
            ;;
        macos)
            get_network_stats_macos
            ;;
        windows)
            get_network_stats_windows
            ;;
        *)
            echo ""
            ;;
    esac
}

# =================================================================
# Network Connection Count
# =================================================================

get_connection_count_linux() {
    if check_command "ss"; then
        ss -tun | grep -c ESTAB
    elif check_command "netstat"; then
        netstat -an | grep -c ESTABLISHED
    else
        echo "0"
    fi
}

get_connection_count_macos() {
    netstat -an | grep -c ESTABLISHED
}

get_connection_count_windows() {
    netstat -an | grep -c ESTABLISHED
}

get_connection_count() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_connection_count_linux
            ;;
        macos)
            get_connection_count_macos
            ;;
        windows)
            get_connection_count_windows
            ;;
        *)
            echo "0"
            ;;
    esac
}

# =================================================================
# Active Network Interfaces
# =================================================================

get_active_interfaces_linux() {
    ip link show | grep "state UP" | awk -F: '{print $2}' | xargs | sed 's/ /", "/g'
}

get_active_interfaces_macos() {
    ifconfig | grep "status: active" -B5 | grep "^[a-z]" | awk -F: '{print $1}' | xargs | sed 's/ /", "/g'
}

get_active_interfaces_windows() {
    ipconfig | grep "adapter" | awk -F: '{print $1}' | sed 's/.*adapter //' | head -3 | xargs | sed 's/ /", "/g'
}

get_active_interfaces() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            get_active_interfaces_linux
            ;;
        macos)
            get_active_interfaces_macos
            ;;
        windows)
            get_active_interfaces_windows
            ;;
        *)
            echo ""
            ;;
    esac
}

# =================================================================
# Main Function - Output JSON
# =================================================================

collect_network_metrics() {
    local network_stats=$(get_network_stats)
    local connection_count=$(get_connection_count)
    local active_interfaces=$(get_active_interfaces)
    
    cat <<EOF
{
  "interfaces": [$network_stats],
  "active_connections": $connection_count,
  "active_interface_names": ["$active_interfaces"],
  "timestamp": "$(get_iso_timestamp)"
}
EOF
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    collect_network_metrics
fi
