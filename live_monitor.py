"""
Live System Monitor - Real-time Dashboard for Windows
Continuously updates with CPU temps, GPU temps, and all metrics
"""

import psutil
import platform
import time
import os
from datetime import datetime

def clear_screen():
    """Clear the console screen"""
    os.system('cls' if os.name == 'nt' else 'clear')

def get_cpu_temp():
    """Try to get CPU temperature (Windows is limited)"""
    try:
        # Try psutil sensors (works on some Windows systems)
        temps = psutil.sensors_temperatures()
        if temps:
            for name, entries in temps.items():
                for entry in entries:
                    if 'cpu' in name.lower() or 'core' in entry.label.lower():
                        return entry.current
    except:
        pass
    return None

def get_gpu_info():
    """Try to get GPU information - Enhanced for WSL"""
    try:
        import subprocess
        
        # Try nvidia-smi for NVIDIA GPUs (works in WSL2)
        try:
            result = subprocess.run(
                ['nvidia-smi', '--query-gpu=gpu_name,temperature.gpu,utilization.gpu,memory.used,memory.total', 
                 '--format=csv,noheader'], 
                capture_output=True, text=True, timeout=3
            )
            
            if result.returncode == 0 and result.stdout.strip():
                # Parse output: "GPU Name, Temp, Util, Mem Used, Mem Total"
                output = result.stdout.strip()
                parts = [p.strip() for p in output.split(',')]
                
                if len(parts) >= 5:
                    gpu_name = parts[0]
                    temp = float(parts[1]) if parts[1].replace('.','').isdigit() else 0
                    util = float(parts[2].replace('%','').strip()) if '%' in parts[2] else float(parts[2])
                    mem_used = float(parts[3].split()[0]) if parts[3] else 0
                    mem_total = float(parts[4].split()[0]) if parts[4] else 1
                    
                    return {
                        'available': True,
                        'temperature': temp,
                        'utilization': util,
                        'memory_used_mb': mem_used,
                        'memory_total_mb': mem_total,
                        'type': f'NVIDIA - {gpu_name}'
                    }
        except FileNotFoundError:
            pass  # nvidia-smi not found
        except Exception as e:
            print(f"nvidia-smi error: {e}")
        
        # Try AMD ROCm
        try:
            result = subprocess.run(['rocm-smi', '--showuse'], capture_output=True, text=True, timeout=2)
            if result.returncode == 0:
                return {
                    'available': True,
                    'temperature': 0,
                    'utilization': 0,
                    'memory_used_mb': 0,
                    'memory_total_mb': 0,
                    'type': 'AMD'
                }
        except:
            pass
            
    except Exception as e:
        print(f"GPU detection error: {e}")
    
    return {'available': False}

def format_bytes(bytes_val):
    """Format bytes to human readable"""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if bytes_val < 1024:
            return f"{bytes_val:.2f} {unit}"
        bytes_val /= 1024
    return f"{bytes_val:.2f} PB"

def create_bar(percent, width=30):
    """Create a progress bar"""
    filled = int(width * percent / 100)
    bar = '█' * filled + '░' * (width - filled)
    
    # Color coding
    if percent >= 90:
        color = '🔴'
    elif percent >= 70:
        color = '🟡'
    else:
        color = '🟢'
    
    return f"{color} [{bar}] {percent:.1f}%"

def get_live_metrics():
    """Collect all system metrics"""
    # CPU
    cpu_percent = psutil.cpu_percent(interval=0.5, percpu=False)
    cpu_per_core = psutil.cpu_percent(interval=0, percpu=True)
    cpu_freq = psutil.cpu_freq()
    cpu_temp = get_cpu_temp()
    
    # Memory
    memory = psutil.virtual_memory()
    swap = psutil.swap_memory()
    
    # Disk I/O
    disk_io = psutil.disk_io_counters()
    
    # Network I/O
    net_io = psutil.net_io_counters()
    
    # GPU
    gpu = get_gpu_info()
    
    # Process info
    process_count = len(psutil.pids())
    
    return {
        'cpu': {
            'percent': cpu_percent,
            'per_core': cpu_per_core,
            'freq_current': cpu_freq.current if cpu_freq else 0,
            'freq_max': cpu_freq.max if cpu_freq else 0,
            'temp': cpu_temp,
            'count': psutil.cpu_count()
        },
        'memory': memory,
        'swap': swap,
        'disk_io': disk_io,
        'net_io': net_io,
        'gpu': gpu,
        'processes': process_count,
        'timestamp': datetime.now()
    }

def display_dashboard(metrics, previous_net=None, previous_disk=None):
    """Display the live monitoring dashboard"""
    clear_screen()
    
    # Header
    print("=" * 80)
    print("🖥️  LIVE SYSTEM MONITOR - Real-time Dashboard".center(80))
    print("=" * 80)
    print(f"⏰ {metrics['timestamp'].strftime('%Y-%m-%d %H:%M:%S')}".center(80))
    print(f"💻 {platform.node()} | {platform.system()} {platform.release()}".center(80))
    print("=" * 80)
    
    # CPU Section
    print("\n🔥 CPU METRICS")
    print("-" * 80)
    print(f"Overall Usage: {create_bar(metrics['cpu']['percent'])}")
    
    if metrics['cpu']['temp']:
        temp_color = '🔴' if metrics['cpu']['temp'] > 80 else '🟡' if metrics['cpu']['temp'] > 70 else '🟢'
        print(f"Temperature:   {temp_color} {metrics['cpu']['temp']:.1f}°C")
    else:
        print(f"Temperature:   ⚠️  Not available (requires admin rights or OpenHardwareMonitor)")
    
    print(f"Frequency:     {metrics['cpu']['freq_current']:.0f} MHz / {metrics['cpu']['freq_max']:.0f} MHz")
    print(f"Cores:         {metrics['cpu']['count']}")
    
    # Per-core usage
    print("\nPer-Core Usage:")
    for i, percent in enumerate(metrics['cpu']['per_core']):
        if i % 4 == 0 and i > 0:
            print()
        print(f"  Core {i:2d}: {percent:5.1f}%", end="  ")
    print("\n")
    
    # Memory Section
    print("💾 MEMORY")
    print("-" * 80)
    mem = metrics['memory']
    print(f"RAM Usage:     {create_bar(mem.percent)}")
    print(f"               {mem.used / (1024**3):.2f} GB / {mem.total / (1024**3):.2f} GB used")
    print(f"Available:     {mem.available / (1024**3):.2f} GB")
    
    swap = metrics['swap']
    if swap.total > 0:
        print(f"\n💿 Page File:  {create_bar(swap.percent)}")
        print(f"               {swap.used / (1024**3):.2f} GB / {swap.total / (1024**3):.2f} GB used")
    
    # Disk I/O
    print("\n📀 DISK I/O")
    print("-" * 80)
    disk_io = metrics['disk_io']
    
    if previous_disk:
        read_rate = (disk_io.read_bytes - previous_disk.read_bytes) / 1024 / 1024  # MB/s
        write_rate = (disk_io.write_bytes - previous_disk.write_bytes) / 1024 / 1024  # MB/s
        print(f"Read Speed:    {read_rate:8.2f} MB/s")
        print(f"Write Speed:   {write_rate:8.2f} MB/s")
    
    print(f"Total Read:    {format_bytes(disk_io.read_bytes)}")
    print(f"Total Written: {format_bytes(disk_io.write_bytes)}")
    
    # Network I/O
    print("\n🌐 NETWORK")
    print("-" * 80)
    net_io = metrics['net_io']
    
    if previous_net:
        upload_rate = (net_io.bytes_sent - previous_net.bytes_sent) / 1024 / 1024  # MB/s
        download_rate = (net_io.bytes_recv - previous_net.bytes_recv) / 1024 / 1024  # MB/s
        print(f"Upload Speed:   {upload_rate:8.2f} MB/s")
        print(f"Download Speed: {download_rate:8.2f} MB/s")
    
    print(f"Total Sent:     {format_bytes(net_io.bytes_sent)}")
    print(f"Total Received: {format_bytes(net_io.bytes_recv)}")
    print(f"Packets Sent:   {net_io.packets_sent:,}")
    print(f"Packets Recv:   {net_io.packets_recv:,}")
    
    # GPU Section
    print("\n🎮 GPU")
    print("-" * 80)
    gpu = metrics['gpu']
    if gpu['available']:
        print(f"Type:          {gpu['type']}")
        print(f"Utilization:   {create_bar(gpu['utilization'])}")
        
        temp_color = '🔴' if gpu['temperature'] > 80 else '🟡' if gpu['temperature'] > 70 else '🟢'
        print(f"Temperature:   {temp_color} {gpu['temperature']:.1f}°C")
        
        mem_percent = (gpu['memory_used_mb'] / gpu['memory_total_mb']) * 100
        print(f"Memory:        {create_bar(mem_percent)}")
        print(f"               {gpu['memory_used_mb']:.0f} MB / {gpu['memory_total_mb']:.0f} MB")
    else:
        print("⚠️  No GPU detected or nvidia-smi not available")
    
    # Disk Usage
    print("\n💽 DISK USAGE")
    print("-" * 80)
    for partition in psutil.disk_partitions():
        try:
            usage = psutil.disk_usage(partition.mountpoint)
            print(f"{partition.mountpoint:5s} {create_bar(usage.percent)}")
            print(f"      {usage.used / (1024**3):.1f} GB / {usage.total / (1024**3):.1f} GB "
                  f"(Free: {usage.free / (1024**3):.1f} GB)")
        except:
            continue
    
    # Bottom info
    print("\n" + "=" * 80)
    print(f"Total Processes: {metrics['processes']}".center(80))
    print("Press Ctrl+C to exit | Updates every 2 seconds".center(80))
    print("=" * 80)

def main():
    """Main loop for live monitoring"""
    print("Starting Live System Monitor...")
    print("Loading...")
    time.sleep(1)
    
    previous_net = None
    previous_disk = None
    
    try:
        while True:
            # Get current metrics
            metrics = get_live_metrics()
            
            # Display dashboard
            display_dashboard(metrics, previous_net, previous_disk)
            
            # Store for rate calculations
            previous_net = metrics['net_io']
            previous_disk = metrics['disk_io']
            
            # Wait before next update
            time.sleep(2)
            
    except KeyboardInterrupt:
        print("\n\n" + "=" * 80)
        print("Monitor stopped. Thanks for using Live System Monitor!".center(80))
        print("=" * 80)

if __name__ == '__main__':
    main()
