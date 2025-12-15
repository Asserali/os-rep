#!/bin/bash
# =================================================================
# System Monitoring Utility Functions
# Central utilities for logging, error handling, and platform detection
# =================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="${PROJECT_ROOT}/data/logs"
LOG_FILE="${LOG_DIR}/monitor.log"
ERROR_LOG="${LOG_DIR}/error.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# =================================================================
# Logging Functions
# =================================================================

# Log message with timestamp
log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} ${timestamp} - ${message}"
    echo "[INFO] ${timestamp} - ${message}" >> "$LOG_FILE"
}

log_warn() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARN]${NC} ${timestamp} - ${message}"
    echo "[WARN] ${timestamp} - ${message}" >> "$LOG_FILE"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} ${timestamp} - ${message}" >&2
    echo "[ERROR] ${timestamp} - ${message}" >> "$ERROR_LOG"
    echo "[ERROR] ${timestamp} - ${message}" >> "$LOG_FILE"
}

log_debug() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - ${message}"
        echo "[DEBUG] ${timestamp} - ${message}" >> "$LOG_FILE"
    fi
}

# =================================================================
# Platform Detection
# =================================================================

detect_platform() {
    local os_type=$(uname -s)
    case "$os_type" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

get_distribution() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# =================================================================
# Error Handling
# =================================================================

check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        return 1
    fi
    return 0
}

check_dependencies() {
    local missing_deps=()
    
    for cmd in "$@"; do
        if ! check_command "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_warn "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
    return 0
}

safe_execute() {
    local cmd="$1"
    local output
    local exit_code
    
    output=$(eval "$cmd" 2>&1)
    exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        log_error "Command failed: $cmd (exit code: $exit_code)"
        log_debug "Command output: $output"
        return $exit_code
    fi
    
    echo "$output"
    return 0
}

# =================================================================
# Data Formatting
# =================================================================

to_json() {
    local key="$1"
    local value="$2"
    echo "\"$key\": \"$value\""
}

to_json_number() {
    local key="$1"
    local value="$2"
    echo "\"$key\": $value"
}

format_bytes() {
    local bytes=$1
    if [ $bytes -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}") GB"
    elif [ $bytes -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB"
    elif [ $bytes -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}") KB"
    else
        echo "$bytes bytes"
    fi
}

format_percentage() {
    local value=$1
    printf "%.2f%%" "$value"
}

# =================================================================
# File Operations
# =================================================================

ensure_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" 2>/dev/null
        if [ $? -ne 0 ]; then
            log_error "Failed to create directory: $dir"
            return 1
        fi
        log_debug "Created directory: $dir"
    fi
    return 0
}

get_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

get_iso_timestamp() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

# =================================================================
# Threshold Checking
# =================================================================

check_threshold() {
    local value=$1
    local warning_threshold=$2
    local critical_threshold=$3
    
    if (( $(echo "$value >= $critical_threshold" | bc -l) )); then
        echo "CRITICAL"
        return 2
    elif (( $(echo "$value >= $warning_threshold" | bc -l) )); then
        echo "WARNING"
        return 1
    else
        echo "OK"
        return 0
    fi
}

# =================================================================
# Validation
# =================================================================

is_number() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+\.?[0-9]*$ ]]
}

is_valid_json() {
    local json="$1"
    echo "$json" | python3 -m json.tool &>/dev/null
    return $?
}

# =================================================================
# System Information
# =================================================================

get_hostname() {
    hostname 2>/dev/null || echo "unknown"
}

get_uptime_seconds() {
    local platform=$(detect_platform)
    case "$platform" in
        linux)
            cat /proc/uptime | awk '{print $1}'
            ;;
        macos)
            sysctl -n kern.boottime | awk '{print $4}' | sed 's/,//' | \
                xargs -I {} date -ju -r {} +%s | \
                xargs -I {} bash -c 'echo $(( $(date +%s) - {} ))'
            ;;
        *)
            echo "0"
            ;;
    esac
}

format_uptime() {
    local total_seconds=$1
    local days=$((total_seconds / 86400))
    local hours=$(( (total_seconds % 86400) / 3600 ))
    local minutes=$(( (total_seconds % 3600) / 60 ))
    
    echo "${days}d ${hours}h ${minutes}m"
}

# =================================================================
# Cleanup
# =================================================================

cleanup_old_files() {
    local dir="$1"
    local days_to_keep="${2:-7}"
    
    if [ ! -d "$dir" ]; then
        return 0
    fi
    
    log_debug "Cleaning up files older than $days_to_keep days in $dir"
    find "$dir" -type f -mtime +$days_to_keep -delete 2>/dev/null
}

# =================================================================
# Export functions for use in other scripts
# =================================================================

export -f log_info log_warn log_error log_debug
export -f detect_platform get_distribution
export -f check_command check_dependencies safe_execute
export -f to_json to_json_number format_bytes format_percentage
export -f ensure_directory get_timestamp get_iso_timestamp
export -f check_threshold is_number is_valid_json
export -f get_hostname get_uptime_seconds format_uptime
export -f cleanup_old_files
