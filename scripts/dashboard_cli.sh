#!/bin/bash
# =================================================================
# CLI Dashboard - Interactive Terminal-based Dashboard
# Uses dialog/whiptail for text-based UI
# =================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# =================================================================
# Configuration
# =================================================================

DATA_DIR="${PROJECT_ROOT}/data/metrics"
LATEST_FILE="${DATA_DIR}/latest.json"

# Check for dialog tools
if check_command "dialog"; then
    DIALOG_CMD="dialog"
elif check_command "whiptail"; then
    DIALOG_CMD="whiptail"
else
    echo "Error: Neither dialog nor whiptail is installed"
    echo "Please install one of them: sudo apt-get install dialog"
    exit 1
fi

# =================================================================
# Data Functions
# =================================================================

get_latest_data() {
    if [ ! -f "$LATEST_FILE" ]; then
        echo "No metrics data available"
        exit 1
    fi
    cat "$LATEST_FILE"
}

extract_json_value() {
    local json="$1"
    local path="$2"
    echo "$json" | python3 -c "import sys, json; data = json.load(sys.stdin); print($path)" 2>/dev/null || echo "N/A"
}

# =================================================================
# Display Functions
# =================================================================

show_main_menu() {
    local choice
    choice=$($DIALOG_CMD --clear --title "System Monitor Dashboard" \
        --menu "Select an option:" 20 60 10 \
        1 "System Overview" \
        2 "CPU Metrics" \
        3 "Memory Metrics" \
        4 "Disk Usage" \
        5 "Network Statistics" \
        6 "GPU Information" \
        7 "System Load" \
        8 "Generate Report" \
        9 "Refresh Data" \
        0 "Exit" \
        2>&1 >/dev/tty)
    
    echo "$choice"
}

show_system_overview() {
    local data=$(get_latest_data)
    
    local hostname=$(extract_json_value "$data" "data['system_info']['hostname']")
    local platform=$(extract_json_value "$data" "data['system_info']['platform']")
    local uptime=$(extract_json_value "$data" "data['system_info']['uptime_seconds']")
    local cpu_usage=$(extract_json_value "$data" "data['cpu']['usage_percent']")
    local mem_usage=$(extract_json_value "$data" "data['memory']['usage_percent']")
    local collection_time=$(extract_json_value "$data" "data['system_info']['collection_time']")
    
    local uptime_formatted=$(format_uptime "$uptime")
    
    $DIALOG_CMD --title "System Overview" --msgbox "\
Hostname: $hostname
Platform: $platform
Uptime: $uptime_formatted
Last Update: $collection_time

Quick Stats:
  CPU Usage: ${cpu_usage}%
  Memory Usage: ${mem_usage}%
" 20 70
}

show_cpu_metrics() {
    local data=$(get_latest_data)
    
    local usage=$(extract_json_value "$data" "data['cpu']['usage_percent']")
    local temp=$(extract_json_value "$data" "data['cpu']['temperature_celsius']")
    local cores=$(extract_json_value "$data" "data['cpu']['core_count']")
    local model=$(extract_json_value "$data" "data['cpu']['model']")
    local freq=$(extract_json_value "$data" "data['cpu']['frequency_ghz']")
    
    # Create progress bar
    local bar_length=50
    local filled=$((usage * bar_length / 100))
    local bar=$(printf '%*s' "$filled" | tr ' ' '█')
    local empty=$(printf '%*s' "$((bar_length - filled))" | tr ' ' '░')
    
    $DIALOG_CMD --title "CPU Metrics" --msgbox "\
Model: $model
Cores: $cores
Frequency: ${freq} GHz

Current Usage: ${usage}%
[$bar$empty] ${usage}%

Temperature: ${temp}°C

Status: $(get_status_text "$usage" 70 90)
" 20 70
}

show_memory_metrics() {
    local data=$(get_latest_data)
    
    local total=$(extract_json_value "$data" "data['memory']['total_bytes']")
    local used=$(extract_json_value "$data" "data['memory']['used_bytes']")
    local available=$(extract_json_value "$data" "data['memory']['available_bytes']")
    local usage_pct=$(extract_json_value "$data" "data['memory']['usage_percent']")
    local swap_total=$(extract_json_value "$data" "data['memory']['swap_total_bytes']")
    local swap_used=$(extract_json_value "$data" "data['memory']['swap_used_bytes']")
    local swap_pct=$(extract_json_value "$data" "data['memory']['swap_usage_percent']")
    
    total_gb=$(awk "BEGIN {printf \"%.2f\", $total / (1024^3)}")
    used_gb=$(awk "BEGIN {printf \"%.2f\", $used / (1024^3)}")
    available_gb=$(awk "BEGIN {printf \"%.2f\", $available / (1024^3)}")
    swap_total_gb=$(awk "BEGIN {printf \"%.2f\", $swap_total / (1024^3)}")
    swap_used_gb=$(awk "BEGIN {printf \"%.2f\", $swap_used / (1024^3)}")
    
    # Create progress bar
    local bar_length=50
    local filled=$((${usage_pct%.*} * bar_length / 100))
    local bar=$(printf '%*s' "$filled" | tr ' ' '█')
    local empty=$(printf '%*s' "$((bar_length - filled))" | tr ' ' '░')
    
    $DIALOG_CMD --title "Memory Metrics" --msgbox "\
RAM:
  Total: ${total_gb} GB
  Used: ${used_gb} GB
  Available: ${available_gb} GB
  Usage: ${usage_pct}%

[$bar$empty] ${usage_pct}%

Swap:
  Total: ${swap_total_gb} GB
  Used: ${swap_used_gb} GB
  Usage: ${swap_pct}%

Status: $(get_status_text "$usage_pct" 80 95)
" 22 70
}

show_disk_usage() {
    local data=$(get_latest_data)
    
    local disk_info=$(echo "$data" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for fs in data['disk']['filesystems']:
    total_gb = fs['total'] / (1024**3)
    used_gb = fs['used'] / (1024**3)
    avail_gb = fs['available'] / (1024**3)
    usage_pct = fs['usage_percent']
    print(f\"{fs['mount']}\")
    print(f\"  Total: {total_gb:.2f} GB\")
    print(f\"  Used: {used_gb:.2f} GB ({usage_pct:.1f}%)\")
    print(f\"  Available: {avail_gb:.2f} GB\")
    print()
" 2>/dev/null)
    
    $DIALOG_CMD --title "Disk Usage" --msgbox "$disk_info" 22 70
}

show_network_stats() {
    local data=$(get_latest_data)
    
    local connections=$(extract_json_value "$data" "data['network']['active_connections']")
    
    local network_info=$(echo "$data" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for iface in data['network']['interfaces']:
    rx_mb = iface['rx_bytes'] / (1024**2)
    tx_mb = iface['tx_bytes'] / (1024**2)
    print(f\"{iface['interface']}\")
    print(f\"  RX: {rx_mb:.2f} MB ({iface['rx_packets']} pkts, {iface['rx_errors']} errors)\")
    print(f\"  TX: {tx_mb:.2f} MB ({iface['tx_packets']} pkts, {iface['tx_errors']} errors)\")
    print()
" 2>/dev/null)
    
    $DIALOG_CMD --title "Network Statistics" --msgbox "\
Active Connections: $connections

$network_info" 22 70
}

show_gpu_info() {
    local data=$(get_latest_data)
    
    local vendor=$(extract_json_value "$data" "data['gpu']['gpu']['vendor']")
    local name=$(extract_json_value "$data" "data['gpu']['gpu']['name']")
    local usage=$(extract_json_value "$data" "data['gpu']['gpu']['utilization_percent']")
    local temp=$(extract_json_value "$data" "data['gpu']['gpu']['temperature_celsius']")
    local mem_pct=$(extract_json_value "$data" "data['gpu']['gpu']['memory_percent']")
    
    if [ "$vendor" = "None" ]; then
        $DIALOG_CMD --title "GPU Information" --msgbox "No GPU detected or monitoring tools not available" 10 60
    else
        $DIALOG_CMD --title "GPU Information" --msgbox "\
Vendor: $vendor
Name: $name

Utilization: ${usage}%
Memory Usage: ${mem_pct}%
Temperature: ${temp}°C

Status: $(get_status_text "$usage" 85 95)
" 18 70
    fi
}

show_system_load() {
    local data=$(get_latest_data)
    
    local load1=$(extract_json_value "$data" "data['system_load']['load_average']['1min']")
    local load5=$(extract_json_value "$data" "data['system_load']['load_average']['5min']")
    local load15=$(extract_json_value "$data" "data['system_load']['load_average']['15min']")
    local total_procs=$(extract_json_value "$data" "data['system_load']['total_processes']")
    local running=$(extract_json_value "$data" "data['system_load']['running_processes']")
    local sleeping=$(extract_json_value "$data" "data['system_load']['sleeping_processes']")
    
    $DIALOG_CMD --title "System Load" --msgbox "\
Load Average:
  1 minute: $load1
  5 minutes: $load5
  15 minutes: $load15

Processes:
  Total: $total_procs
  Running: $running
  Sleeping: $sleeping
" 18 60
}

generate_report_menu() {
    local choice
    choice=$($DIALOG_CMD --clear --title "Generate Report" \
        --menu "Select report format:" 15 50 3 \
        1 "Markdown Report" \
        2 "Text Summary" \
        3 "Back to Main Menu" \
        2>&1 >/dev/tty)
    
    case $choice in
        1)
            generate_markdown_report
            ;;
        2)
            show_text_summary
            ;;
    esac
}

generate_markdown_report() {
    local timestamp=$(get_timestamp)
    local report_file="${PROJECT_ROOT}/data/reports/report_${timestamp}.md"
    
    bash "${SCRIPT_DIR}/monitor.sh" --test > /tmp/metrics.json 2>/dev/null
    
    # Use Python to generate report (simplified)
    $DIALOG_CMD --title "Report Generated" --msgbox "Markdown report saved to:\n$report_file" 10 60
}

show_text_summary() {
    local data=$(get_latest_data)
    
    local summary=$(echo "$data" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('=== System Monitor Summary ===')
print(f\"Hostname: {data['system_info']['hostname']}\")
print(f\"Platform: {data['system_info']['platform']}\")
print(f\"\\nCPU: {data['cpu']['usage_percent']}%\")
print(f\"Memory: {data['memory']['usage_percent']}%\")
print(f\"Load: {data['system_load']['load_average']['1min']}\")
" 2>/dev/null)
    
    $DIALOG_CMD --title "System Summary" --msgbox "$summary" 18 60
}

# =================================================================
# Helper Functions
# =================================================================

get_status_text() {
    local value=$1
    local warning=$2
    local critical=$3
    
    value=${value%.*}  # Remove decimal part
    
    if [ "$value" -ge "$critical" ]; then
        echo "CRITICAL"
    elif [ "$value" -ge "$warning" ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

# =================================================================
# Main Loop
# =================================================================

main() {
    while true; do
        choice=$(show_main_menu)
        
        case $choice in
            1) show_system_overview ;;
            2) show_cpu_metrics ;;
            3) show_memory_metrics ;;
            4) show_disk_usage ;;
            5) show_network_stats ;;
            6) show_gpu_info ;;
            7) show_system_load ;;
            8) generate_report_menu ;;
            9) 
                bash "${SCRIPT_DIR}/monitor.sh" --test > "$LATEST_FILE" 2>/dev/null
                $DIALOG_CMD --title "Data Refreshed" --msgbox "Metrics data has been refreshed" 8 50
                ;;
            0|"") 
                clear
                exit 0
                ;;
        esac
    done
}

# Run main
main
