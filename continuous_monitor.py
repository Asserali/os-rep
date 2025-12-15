"""
Real-time System Monitor - Continuous Updates (Task Manager Style)
Auto-collects metrics every 3 seconds and saves to latest.json
Run this in the background while using the web dashboard
"""

import time
import subprocess
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from monitor_windows import get_system_metrics, save_metrics

def continuous_monitor(interval=3):
    """
    Continuously collect and save metrics
    interval: seconds between collections (default 3)
    """
    print(f"🔄 Starting continuous monitoring (interval: {interval}s)")
    print("📊 Metrics will be saved to: data/metrics/latest.json")
    print("🌐 Web dashboard will auto-update from this data")
    print("Press Ctrl+C to stop\n")
    
    iteration = 0
    try:
        while True:
            iteration += 1
            
            # Collect metrics
            metrics = get_system_metrics()
            
            # Save to file
            save_metrics(metrics)
            
            # Show status
            cpu = metrics['cpu']['usage_percent']
            mem = metrics['memory']['percent']
            gpu_util = metrics.get('gpu', {}).get('utilization', 0) if metrics.get('gpu', {}).get('available') else 0
            
            print(f"[{iteration:04d}] CPU: {cpu:5.1f}% | RAM: {mem:5.1f}% | GPU: {gpu_util:5.1f}%", end='\r')
            
            # Wait for next interval
            time.sleep(interval)
            
    except KeyboardInterrupt:
        print("\n\n✅ Monitoring stopped")
        print(f"Total iterations: {iteration}")

if __name__ == '__main__':
    # Start continuous monitoring with 3 second interval
    continuous_monitor(interval=3)
