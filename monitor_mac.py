#!/usr/bin/env python3
"""
System Monitor - macOS Edition
Collects system metrics using macOS-specific tools and libraries
"""

import os
import json
import platform
import subprocess
from datetime import datetime
from pathlib import Path

try:
    import psutil
except ImportError:
    print("Error: psutil not installed. Run: pip3 install psutil")
    exit(1)


def get_cpu_metrics():
    """Get CPU usage and information"""
    cpu_freq = psutil.cpu_freq()
    
    # Get CPU temperature (macOS-specific)
    temperature = get_cpu_temperature()
    
    return {
        'usage_percent': round(psutil.cpu_percent(interval=1), 1),
        'count': psutil.cpu_count(),
        'frequency_mhz': round(cpu_freq.current, 0) if cpu_freq else 0,
        'temperature': temperature
    }


def get_cpu_temperature():
    """Get CPU temperature using powermetrics or osx-cpu-temp"""
    try:
        # Try osx-cpu-temp if installed
        result = subprocess.run(
            ['osx-cpu-temp'],
            capture_output=True,
            text=True,
            timeout=2
        )
        if result.returncode == 0:
            # Parse output like "61.2°C"
            temp_str = result.stdout.strip().replace('°C', '')
            return round(float(temp_str), 1)
    except (FileNotFoundError, subprocess.TimeoutExpired, ValueError):
        pass
    
    try:
        # Try powermetrics (requires sudo)
        result = subprocess.run(
            ['sudo', 'powermetrics', '--samplers', 'smc', '-i1', '-n1'],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            # Parse CPU die temperature from output
            for line in result.stdout.split('\n'):
                if 'CPU die temperature' in line:
                    temp = line.split(':')[1].strip().split()[0]
                    return round(float(temp), 1)
    except (FileNotFoundError, subprocess.TimeoutExpired, ValueError, PermissionError):
        pass
    
    return None


def get_memory_metrics():
    """Get memory usage information"""
    mem = psutil.virtual_memory()
    return {
        'total_gb': round(mem.total / (1024**3), 2),
        'used_gb': round(mem.used / (1024**3), 2),
        'available_gb': round(mem.available / (1024**3), 2),
        'percent': round(mem.percent, 1)
    }


def get_swap_metrics():
    """Get swap usage information"""
    swap = psutil.swap_memory()
    return {
        'total_gb': round(swap.total / (1024**3), 2),
        'used_gb': round(swap.used / (1024**3), 2),
        'percent': round(swap.percent, 1)
    }


def get_disk_metrics():
    """Get disk usage for all mounted partitions"""
    disks = []
    for partition in psutil.disk_partitions():
        # Skip special filesystems on macOS
        if partition.fstype in ['', 'devfs', 'autofs']:
            continue
        
        try:
            usage = psutil.disk_usage(partition.mountpoint)
            disks.append({
                'device': partition.device,
                'mountpoint': partition.mountpoint,
                'total_gb': round(usage.total / (1024**3), 2),
                'used_gb': round(usage.used / (1024**3), 2),
                'free_gb': round(usage.free / (1024**3), 2),
                'percent': round(usage.percent, 1)
            })
        except (PermissionError, OSError):
            continue
    
    return disks


def get_network_metrics():
    """Get network statistics"""
    net_io = psutil.net_io_counters()
    return {
        'bytes_sent_mb': round(net_io.bytes_sent / (1024**2), 2),
        'bytes_recv_mb': round(net_io.bytes_recv / (1024**2), 2),
        'packets_sent': net_io.packets_sent,
        'packets_recv': net_io.packets_recv
    }


def get_gpu_metrics():
    """Get GPU information (macOS)"""
    # macOS doesn't have nvidia-smi, but can detect GPU via system_profiler
    try:
        result = subprocess.run(
            ['system_profiler', 'SPDisplaysDataType', '-json'],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0:
            import json as json_module
            data = json_module.loads(result.stdout)
            
            # Extract GPU info from the JSON
            if 'SPDisplaysDataType' in data and data['SPDisplaysDataType']:
                gpu_info = data['SPDisplaysDataType'][0]
                gpu_name = gpu_info.get('sppci_model', 'Unknown GPU')
                
                # macOS doesn't provide utilization/temp easily, so return basic info
                return {
                    'available': True,
                    'name': gpu_name,
                    'temperature': None,
                    'utilization': None,
                    'memory_used_mb': None,
                    'memory_total_mb': None
                }
    except (FileNotFoundError, subprocess.TimeoutExpired, Exception):
        pass
    
    return {
        'available': False,
        'name': 'N/A',
        'temperature': 0,
        'utilization': 0,
        'memory_used_mb': 0,
        'memory_total_mb': 0
    }


def get_system_load_metrics():
    """Get system load average and process information"""
    # Get load average (1, 5, 15 minutes)
    load_avg = os.getloadavg()
    
    # Get process information
    processes = list(psutil.process_iter(['name', 'cpu_percent', 'memory_percent', 'status']))
    total_processes = len(processes)
    
    # Count running processes
    running_processes = sum(1 for p in processes if p.info.get('status') == psutil.STATUS_RUNNING)
    sleeping_processes = sum(1 for p in processes if p.info.get('status') == psutil.STATUS_SLEEPING)
    zombie_processes = sum(1 for p in processes if p.info.get('status') == psutil.STATUS_ZOMBIE)
    
    # Get top CPU processes
    top_processes = sorted(
        [{'name': p.info['name'], 
          'cpu_percent': p.info['cpu_percent'] or 0,
          'memory_percent': p.info['memory_percent'] or 0}
         for p in processes],
        key=lambda x: x['cpu_percent'],
        reverse=True
    )[:5]
    
    return {
        'load_average': {
            '1min': round(load_avg[0], 2),
            '5min': round(load_avg[1], 2),
            '15min': round(load_avg[2], 2)
        },
        'total_processes': total_processes,
        'running_processes': running_processes,
        'sleeping_processes': sleeping_processes,
        'zombie_processes': zombie_processes,
        'top_cpu_processes': top_processes,
        'timestamp': datetime.now().isoformat()
    }


def collect_metrics():
    """Collect all system metrics"""
    uname = platform.uname()
    
    metrics = {
        'timestamp': datetime.now().isoformat(),
        'system': {
            'hostname': uname.node,
            'platform': 'Darwin',
            'version': uname.release,
            'architecture': uname.machine
        },
        'cpu': get_cpu_metrics(),
        'memory': get_memory_metrics(),
        'swap': get_swap_metrics(),
        'disk': get_disk_metrics(),
        'network': get_network_metrics(),
        'gpu': get_gpu_metrics(),
        'system_load': get_system_load_metrics()
    }
    
    return metrics


def print_metrics(metrics):
    """Print metrics in a formatted way"""
    print("=" * 60)
    print("SYSTEM MONITOR - macOS Edition")
    print("=" * 60)
    
    print(f"\nTimestamp: {metrics['timestamp']}")
    print(f"Hostname: {metrics['system']['hostname']}")
    print(f"Platform: {metrics['system']['platform']}")
    
    print(f"\nCPU:")
    print(f"   Usage: {metrics['cpu']['usage_percent']}%")
    print(f"   Cores: {metrics['cpu']['count']}")
    print(f"   Frequency: {metrics['cpu']['frequency_mhz']} MHz")
    if metrics['cpu']['temperature']:
        print(f"   Temperature: {metrics['cpu']['temperature']}°C")
    
    print(f"\nMemory:")
    print(f"   Total: {metrics['memory']['total_gb']} GB")
    print(f"   Used: {metrics['memory']['used_gb']} GB ({metrics['memory']['percent']}%)")
    print(f"   Available: {metrics['memory']['available_gb']} GB")
    
    print(f"\nSwap:")
    print(f"   Total: {metrics['swap']['total_gb']} GB")
    print(f"   Used: {metrics['swap']['used_gb']} GB ({metrics['swap']['percent']}%)")
    
    print(f"\nDisk Usage:")
    for disk in metrics['disk']:
        print(f"   {disk['device']} ({disk['mountpoint']}):")
        print(f"      Total: {disk['total_gb']} GB")
        print(f"      Used: {disk['used_gb']} GB ({disk['percent']}%)")
        print(f"      Free: {disk['free_gb']} GB")
    
    print(f"\nNetwork:")
    print(f"   Sent: {metrics['network']['bytes_sent_mb']} MB ({metrics['network']['packets_sent']} packets)")
    print(f"   Received: {metrics['network']['bytes_recv_mb']} MB ({metrics['network']['packets_recv']} packets)")
    
    print(f"\nGPU:")
    if metrics['gpu']['available']:
        print(f"   Name: {metrics['gpu']['name']}")
        if metrics['gpu']['utilization']:
            print(f"   Utilization: {metrics['gpu']['utilization']}%")
        if metrics['gpu']['temperature']:
            print(f"   Temperature: {metrics['gpu']['temperature']}°C")
    else:
        print("   No GPU detected")
    
    print(f"\nSystem Load:")
    print(f"   Load Average: {metrics['system_load']['load_average']['1min']} (1min)")
    print(f"   Total Processes: {metrics['system_load']['total_processes']}")
    print(f"   Running: {metrics['system_load']['running_processes']} | Sleeping: {metrics['system_load']['sleeping_processes']}")
    
    print("=" * 60)


def save_metrics(metrics, filename='latest_mac.json'):
    """Save metrics to JSON file"""
    # Ensure data directory exists
    data_dir = Path(__file__).parent / 'data' / 'metrics'
    data_dir.mkdir(parents=True, exist_ok=True)
    
    filepath = data_dir / filename
    
    with open(filepath, 'w') as f:
        json.dump(metrics, f, indent=2)
    
    print(f"\nMetrics saved to: {filepath}")


if __name__ == '__main__':
    try:
        metrics = collect_metrics()
        print_metrics(metrics)
        save_metrics(metrics)
        
        # Also save as latest.json for backward compatibility
        save_metrics(metrics, 'latest.json')
        
        print("\nJSON Output:")
        print(json.dumps(metrics, indent=2))
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        exit(1)
