#!/bin/bash
# =================================================================
# Main System Monitor Script
# Orchestrates all monitoring collectors and aggregates metrics
# =================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# =================================================================
# Configuration
# =================================================================

CONFIG_FILE="${PROJECT_ROOT}/config/monitor.conf"
DATA_DIR="${PROJECT_ROOT}/data/metrics"

# Default monitoring interval (seconds)
MONITOR_INTERVAL=60

# Test mode flag
TEST_MODE=0

# =================================================================
# Parse Command Line Arguments
# =================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test)
                TEST_MODE=1
                shift
                ;;
            --interval)
                MONITOR_INTERVAL="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat <<EOF
System Monitor - Comprehensive Hardware and Software Monitoring

Usage: $0 [OPTIONS]

Options:
    --test              Run once in test mode and output to console
    --interval SECONDS  Set monitoring interval (default: 60)
    --help              Show this help message

Examples:
    $0                  # Run continuously with default settings
    $0 --test           # Run once and display output
    $0 --interval 30    # Monitor every 30 seconds

EOF
}

# =================================================================
# Load Configuration
# =================================================================

load_configuration() {
    if [ -f "$CONFIG_FILE" ]; then
        log_debug "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        log_warn "Configuration file not found, using defaults"
    fi
}

# =================================================================
# Collect All Metrics
# =================================================================

collect_all_metrics() {
    log_debug "Starting metrics collection..."
    
    local timestamp=$(get_iso_timestamp)
    local hostname=$(get_hostname)
    local platform=$(detect_platform)
    local uptime_seconds=$(get_uptime_seconds)
    
    # Collect metrics from all collectors
    local cpu_metrics=$(bash "${SCRIPT_DIR}/collectors/cpu_monitor.sh" 2>/dev/null)
    local memory_metrics=$(bash "${SCRIPT_DIR}/collectors/memory_monitor.sh" 2>/dev/null)
    local disk_metrics=$(bash "${SCRIPT_DIR}/collectors/disk_monitor.sh" 2>/dev/null)
    local network_metrics=$(bash "${SCRIPT_DIR}/collectors/network_monitor.sh" 2>/dev/null)
    local gpu_metrics=$(bash "${SCRIPT_DIR}/collectors/gpu_monitor.sh" 2>/dev/null)
    local system_metrics=$(bash "${SCRIPT_DIR}/collectors/system_load.sh" 2>/dev/null)
    
    # Aggregate all metrics into single JSON
    cat <<EOF
{
  "system_info": {
    "hostname": "$hostname",
    "platform": "$platform",
    "uptime_seconds": $uptime_seconds,
    "collection_time": "$timestamp"
  },
  "cpu": $cpu_metrics,
  "memory": $memory_metrics,
  "disk": $disk_metrics,
  "network": $network_metrics,
  "gpu": $gpu_metrics,
  "system_load": $system_metrics
}
EOF
}

# =================================================================
# Save Metrics to File
# =================================================================

save_metrics() {
    local metrics="$1"
    
    ensure_directory "$DATA_DIR"
    
    local filename="metrics_$(get_timestamp).json"
    local filepath="${DATA_DIR}/${filename}"
    
    echo "$metrics" > "$filepath"
    
    if [ $? -eq 0 ]; then
        log_info "Metrics saved to $filepath"
        
        # Also save as latest.json for easy access
        echo "$metrics" > "${DATA_DIR}/latest.json"
    else
        log_error "Failed to save metrics to $filepath"
        return 1
    fi
}

# =================================================================
# Check for Alerts
# =================================================================

check_alerts() {
    local metrics="$1"
    
    if [ -f "${SCRIPT_DIR}/alert_manager.sh" ]; then
        log_debug "Checking alert thresholds..."
        echo "$metrics" | bash "${SCRIPT_DIR}/alert_manager.sh"
    fi
}

# =================================================================
# Cleanup Old Metrics
# =================================================================

cleanup_old_metrics() {
    local retention_days="${RETENTION_DAYS:-7}"
    cleanup_old_files "$DATA_DIR" "$retention_days"
}

# =================================================================
# Main Monitoring Loop
# =================================================================

run_monitoring() {
    log_info "System monitoring started"
    log_info "Platform: $(detect_platform)"
    log_info "Hostname: $(get_hostname)"
    log_info "Monitoring interval: ${MONITOR_INTERVAL}s"
    
    while true; do
        # Collect metrics
        local metrics=$(collect_all_metrics)
        
        # Validate JSON
        if is_valid_json "$metrics"; then
            # Save to file
            save_metrics "$metrics"
            
            # Check alerts
            check_alerts "$metrics"
        else
            log_error "Invalid JSON output from collectors"
        fi
        
        # Cleanup old files periodically (every hour)
        if [ $((RANDOM % 60)) -eq 0 ]; then
            cleanup_old_metrics
        fi
        
        # Sleep until next interval
        if [ "$TEST_MODE" -eq 1 ]; then
            break
        fi
        
        sleep "$MONITOR_INTERVAL"
    done
}

# =================================================================
# Test Mode
# =================================================================

run_test() {
    log_info "Running in test mode..."
    
    local metrics=$(collect_all_metrics)
    
    if is_valid_json "$metrics"; then
        echo "$metrics" | python3 -m json.tool
        log_info "Test completed successfully"
        return 0
    else
        log_error "Metrics collection failed or produced invalid JSON"
        echo "$metrics"
        return 1
    fi
}

# =================================================================
# Entry Point
# =================================================================

main() {
    # Parse arguments
    parse_arguments "$@"
    
    # Load configuration
    load_configuration
    
    # Ensure data directory exists
    ensure_directory "$DATA_DIR"
    
    # Run in appropriate mode
    if [ "$TEST_MODE" -eq 1 ]; then
        run_test
    else
        run_monitoring
    fi
}

# Run main function
main "$@"
