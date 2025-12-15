#!/bin/bash
# ============================================================================
# Solution 1 - Continuous Monitor + Dashboard
# Runs metrics collection in background + Dashboard in Docker
# Works on Linux and macOS
# ============================================================================

set -e

echo ""
echo "================================================================"
echo " Solution 1: Host Agent + Container Dashboard"
echo "================================================================"
echo ""

# Detect platform
PLATFORM=$(uname)
if [ "$PLATFORM" == "Darwin" ]; then
    MONITOR_SCRIPT="monitor_mac.py"
    PLATFORM_NAME="macOS"
elif [ "$PLATFORM" == "Linux" ]; then
    MONITOR_SCRIPT="monitor_linux.py"
    PLATFORM_NAME="Linux"
else
    echo "[ERROR] Unsupported platform: $PLATFORM"
    exit 1
fi

echo "Detected platform: $PLATFORM_NAME"
echo ""

# Check if monitor script exists
if [ ! -f "$MONITOR_SCRIPT" ]; then
    echo "[ERROR] Monitor script not found: $MONITOR_SCRIPT"
    echo "Please ensure $MONITOR_SCRIPT exists in the current directory"
    exit 1
fi

# Check if Docker is running
if ! docker ps >/dev/null 2>&1; then
    echo "[ERROR] Docker is not running!"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

# Check if Python is installed
if ! command -v python3 >/dev/null 2>&1; then
    echo "[ERROR] Python 3 is not installed!"
    echo "Please install Python 3 and try again"
    exit 1
fi

# Check if psutil is installed
if ! python3 -c "import psutil" >/dev/null 2>&1; then
    echo "[WARNING] psutil not installed. Installing..."
    pip3 install psutil
fi

echo "[1/2] Starting dashboard container..."
docker-compose -f docker-compose-solution1.yml up -d

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to start dashboard container"
    exit 1
fi

echo ""
echo "[2/2] Starting continuous metrics collection..."
echo "Running in background..."
echo ""

# Start metrics collection in background
nohup bash -c "while true; do python3 $MONITOR_SCRIPT >/dev/null 2>&1; sleep 5; done" >/dev/null 2>&1 &
MONITOR_PID=$!

# Save PID for later stopping
echo $MONITOR_PID > .monitor.pid

echo ""
echo "================================================================"
echo " SUCCESS! Solution 1 is running"
echo "================================================================"
echo ""
echo " Platform:           $PLATFORM_NAME"
echo " Monitor Script:     $MONITOR_SCRIPT (PID: $MONITOR_PID)"
echo " Dashboard URL:      http://localhost:8080"
echo ""
echo " Management Commands:"
echo " --------------------"
echo " View logs:       docker logs -f system-monitor-dashboard"
echo " Stop dashboard:  docker-compose -f docker-compose-solution1.yml down"
echo " Stop metrics:    kill $MONITOR_PID  (or: kill \$(cat .monitor.pid))"
echo " Stop both:       ./stop_solution1.sh"
echo ""
echo " Opening dashboard in browser..."

# Open browser based on platform
if [ "$PLATFORM" == "Darwin" ]; then
    # macOS
    sleep 2
    open http://localhost:8080
elif [ "$PLATFORM" == "Linux" ]; then
    # Linux - try common browsers
    sleep 2
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open http://localhost:8080 >/dev/null 2>&1 &
    elif command -v gnome-open >/dev/null 2>&1; then
        gnome-open http://localhost:8080 >/dev/null 2>&1 &
    elif command -v firefox >/dev/null 2>&1; then
        firefox http://localhost:8080 >/dev/null 2>&1 &
    else
        echo " (Please open http://localhost:8080 manually)"
    fi
fi

echo ""
echo "================================================================"
echo ""
