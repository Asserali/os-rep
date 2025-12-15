#!/bin/bash
# =================================================================
# GPU Monitor - Cross-platform GPU utilization and health
# =================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# =================================================================
# NVIDIA GPU Monitoring
# =================================================================

get_nvidia_gpu_info() {
    if ! check_command "nvidia-smi"; then
        return 1
    fi
    
    local gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits | head -1)
    local gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
    local gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1)
    local gpu_mem_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -1)
    local gpu_mem_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
    local gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -1)
    local gpu_power=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits | head -1)
    
    # Convert MB to bytes
    gpu_mem_used=$((gpu_mem_used * 1048576))
    gpu_mem_total=$((gpu_mem_total * 1048576))
    
    local gpu_mem_percent=$(awk "BEGIN {printf \"%.2f\", ($gpu_mem_used / $gpu_mem_total) * 100}")
    
    cat <<EOF
{
  "vendor": "NVIDIA",
  "name": "$gpu_name",
  "count": $gpu_count,
  "utilization_percent": $gpu_util,
  "memory_used_bytes": $gpu_mem_used,
  "memory_total_bytes": $gpu_mem_total,
  "memory_percent": $gpu_mem_percent,
  "temperature_celsius": $gpu_temp,
  "power_watts": $gpu_power
}
EOF
    return 0
}

# =================================================================
# AMD GPU Monitoring
# =================================================================

get_amd_gpu_info() {
    if ! check_command "rocm-smi"; then
        return 1
    fi
    
    local gpu_name=$(rocm-smi --showproductname | grep "GPU" | awk -F: '{print $2}' | xargs | head -1)
    local gpu_util=$(rocm-smi --showuse | grep "GPU use" | awk '{print $4}' | sed 's/%//' | head -1)
    local gpu_temp=$(rocm-smi --showtemp | grep "Temperature" | awk '{print $3}' | head -1)
    
    cat <<EOF
{
  "vendor": "AMD",
  "name": "$gpu_name",
  "count": 1,
  "utilization_percent": ${gpu_util:-0},
  "memory_used_bytes": 0,
  "memory_total_bytes": 0,
  "memory_percent": 0.00,
  "temperature_celsius": ${gpu_temp:-0},
  "power_watts": 0
}
EOF
    return 0
}

# =================================================================
# Intel GPU Monitoring  
# =================================================================

get_intel_gpu_info() {
    if ! check_command "intel_gpu_top"; then
        return 1
    fi
    
    # Intel GPU monitoring is complex, providing basic info
    cat <<EOF
{
  "vendor": "Intel",
  "name": "Intel Integrated GPU",
  "count": 1,
  "utilization_percent": 0,
  "memory_used_bytes": 0,
  "memory_total_bytes": 0,
  "memory_percent": 0.00,
  "temperature_celsius": 0,
  "power_watts": 0
}
EOF
    return 0
}

# =================================================================
# Generic GPU Detection
# =================================================================

detect_gpu() {
    # Try NVIDIA first
    if get_nvidia_gpu_info 2>/dev/null; then
        return 0
    fi
    
    # Try AMD
    if get_amd_gpu_info 2>/dev/null; then
        return 0
    fi
    
    # Try Intel
    if get_intel_gpu_info 2>/dev/null; then
        return 0
    fi
    
    # No GPU detected or no monitoring tools available
    cat <<EOF
{
  "vendor": "None",
  "name": "No GPU detected or monitoring tools not available",
  "count": 0,
  "utilization_percent": 0,
  "memory_used_bytes": 0,
  "memory_total_bytes": 0,
  "memory_percent": 0.00,
  "temperature_celsius": 0,
  "power_watts": 0
}
EOF
    return 1
}

# =================================================================
# Main Function - Output JSON
# =================================================================

collect_gpu_metrics() {
    local gpu_info=$(detect_gpu)
    
    cat <<EOF
{
  "gpu": $gpu_info,
  "timestamp": "$(get_iso_timestamp)"
}
EOF
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    collect_gpu_metrics
fi
