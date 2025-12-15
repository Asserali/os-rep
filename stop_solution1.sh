#!/bin/bash
# ============================================================================
# Stop Solution 1 - Stop both dashboard and metrics collection
# ============================================================================

echo ""
echo "================================================================"
echo " Stopping Solution 1"
echo "================================================================"
echo ""

# Stop dashboard container
echo "[1/2] Stopping dashboard container..."
docker-compose -f docker-compose-solution1.yml down

# Stop metrics collection
echo "[2/2] Stopping metrics collection..."
if [ -f .monitor.pid ]; then
    PID=$(cat .monitor.pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "Stopped metrics collection (PID: $PID)"
    else
        echo "Metrics collection already stopped"
    fi
    rm .monitor.pid
else
    echo "No PID file found, metrics collection may not be running"
fi

echo ""
echo "================================================================"
echo " Solution 1 stopped successfully"
echo "================================================================"
echo ""
