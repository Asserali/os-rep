"""
System Monitor GUI - Graphical Interface with Real-time Updates
Uses tkinter for cross-platform GUI
"""

import tkinter as tk
from tkinter import ttk
import psutil
import platform
import threading
import time
from datetime import datetime

class SystemMonitorGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("System Monitor - Real-time Dashboard")
        self.root.geometry("900x700")
        self.root.configure(bg='#1e1e1e')
        
        # Flag to control updates
        self.running = True
        
        # Create main container
        main_frame = tk.Frame(root, bg='#1e1e1e')
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Header
        header = tk.Label(main_frame, text="🖥️ SYSTEM MONITOR", 
                         font=('Arial', 20, 'bold'), bg='#1e1e1e', fg='#00ff00')
        header.pack(pady=10)
        
        # System info
        self.system_label = tk.Label(main_frame, text="", font=('Courier', 10), 
                                     bg='#1e1e1e', fg='#ffffff', justify=tk.LEFT)
        self.system_label.pack(pady=5)
        
        # Create notebook for tabs
        style = ttk.Style()
        style.theme_use('default')
        style.configure('TNotebook', background='#1e1e1e')
        style.configure('TNotebook.Tab', background='#2d2d2d', foreground='white', 
                       padding=[20, 10])
        style.map('TNotebook.Tab', background=[('selected', '#00ff00')],
                 foreground=[('selected', 'black')])
        
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True, pady=10)
        
        # CPU Tab
        cpu_frame = tk.Frame(self.notebook, bg='#1e1e1e')
        self.notebook.add(cpu_frame, text='CPU')
        self.setup_cpu_tab(cpu_frame)
        
        # Memory Tab
        memory_frame = tk.Frame(self.notebook, bg='#1e1e1e')
        self.notebook.add(memory_frame, text='Memory')
        self.setup_memory_tab(memory_frame)
        
        # Disk Tab
        disk_frame = tk.Frame(self.notebook, bg='#1e1e1e')
        self.notebook.add(disk_frame, text='Disk')
        self.setup_disk_tab(disk_frame)
        
        # Network Tab
        network_frame = tk.Frame(self.notebook, bg='#1e1e1e')
        self.notebook.add(network_frame, text='Network')
        self.setup_network_tab(network_frame)
        
        # GPU Tab
        gpu_frame = tk.Frame(self.notebook, bg='#1e1e1e')
        self.notebook.add(gpu_frame, text='GPU')
        self.setup_gpu_tab(gpu_frame)
        
        # Status bar
        self.status_bar = tk.Label(root, text="Updating...", bg='#00ff00', 
                                  fg='black', font=('Arial', 9), anchor=tk.W)
        self.status_bar.pack(side=tk.BOTTOM, fill=tk.X)
        
        # Start update thread
        self.update_thread = threading.Thread(target=self.update_loop, daemon=True)
        self.update_thread.start()
        
        # Handle window close
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
    
    def setup_cpu_tab(self, parent):
        """Setup CPU monitoring tab"""
        self.cpu_usage_label = tk.Label(parent, text="", font=('Courier', 12, 'bold'),
                                       bg='#1e1e1e', fg='#00ff00', justify=tk.LEFT)
        self.cpu_usage_label.pack(pady=10)
        
        self.cpu_progress = ttk.Progressbar(parent, length=600, mode='determinate')
        self.cpu_progress.pack(pady=5)
        
        self.cpu_details = tk.Text(parent, height=20, width=80, bg='#2d2d2d', 
                                  fg='#ffffff', font=('Courier', 10))
        self.cpu_details.pack(pady=10, padx=10)
    
    def setup_memory_tab(self, parent):
        """Setup Memory monitoring tab"""
        self.memory_label = tk.Label(parent, text="", font=('Courier', 12, 'bold'),
                                    bg='#1e1e1e', fg='#00ff00', justify=tk.LEFT)
        self.memory_label.pack(pady=10)
        
        self.memory_progress = ttk.Progressbar(parent, length=600, mode='determinate')
        self.memory_progress.pack(pady=5)
        
        self.memory_details = tk.Text(parent, height=20, width=80, bg='#2d2d2d',
                                     fg='#ffffff', font=('Courier', 10))
        self.memory_details.pack(pady=10, padx=10)
    
    def setup_disk_tab(self, parent):
        """Setup Disk monitoring tab"""
        self.disk_label = tk.Label(parent, text="Disk Usage", font=('Courier', 12, 'bold'),
                                  bg='#1e1e1e', fg='#00ff00')
        self.disk_label.pack(pady=10)
        
        self.disk_details = tk.Text(parent, height=20, width=80, bg='#2d2d2d',
                                   fg='#ffffff', font=('Courier', 10))
        self.disk_details.pack(pady=10, padx=10)
    
    def setup_network_tab(self, parent):
        """Setup Network monitoring tab"""
        self.network_label = tk.Label(parent, text="Network Activity", 
                                     font=('Courier', 12, 'bold'),
                                     bg='#1e1e1e', fg='#00ff00')
        self.network_label.pack(pady=10)
        
        self.network_details = tk.Text(parent, height=20, width=80, bg='#2d2d2d',
                                      fg='#ffffff', font=('Courier', 10))
        self.network_details.pack(pady=10, padx=10)
    
    def setup_gpu_tab(self, parent):
        """Setup GPU monitoring tab"""
        self.gpu_label = tk.Label(parent, text="GPU Information", 
                                 font=('Courier', 12, 'bold'),
                                 bg='#1e1e1e', fg='#00ff00')
        self.gpu_label.pack(pady=10)
        
        self.gpu_details = tk.Text(parent, height=20, width=80, bg='#2d2d2d',
                                  fg='#ffffff', font=('Courier', 10))
        self.gpu_details.pack(pady=10, padx=10)
    
    def get_gpu_info(self):
        """Get GPU information with all available metrics"""
        try:
            import subprocess
            result = subprocess.run(
                ['nvidia-smi', '--query-gpu=gpu_name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total,power.draw,power.limit,clocks.gr,clocks.mem,fan.speed', 
                 '--format=csv,noheader,nounits'], 
                capture_output=True, text=True, timeout=3
            )
            
            if result.returncode == 0 and result.stdout.strip():
                output = result.stdout.strip()
                parts = [p.strip() for p in output.split(',')]
                
                if len(parts) >= 11:
                    return {
                        'name': parts[0],
                        'temp': float(parts[1]) if parts[1].replace('.','').replace('-','').isdigit() else 0,
                        'util': float(parts[2]) if parts[2].replace('.','').replace('-','').isdigit() else 0,
                        'mem_util': float(parts[3]) if parts[3].replace('.','').replace('-','').isdigit() else 0,
                        'mem_used': float(parts[4]) if parts[4].replace('.','').replace('-','').isdigit() else 0,
                        'mem_total': float(parts[5]) if parts[5].replace('.','').replace('-','').isdigit() else 0,
                        'power_draw': float(parts[6]) if parts[6].replace('.','').replace('-','').isdigit() else 0,
                        'power_limit': float(parts[7]) if parts[7].replace('.','').replace('-','').isdigit() else 0,
                        'clock_gpu': float(parts[8]) if parts[8].replace('.','').replace('-','').isdigit() else 0,
                        'clock_mem': float(parts[9]) if parts[9].replace('.','').replace('-','').isdigit() else 0,
                        'fan_speed': float(parts[10]) if parts[10].replace('.','').replace('-','').isdigit() else 0
                    }
        except:
            pass
        return None
    
    def get_cpu_temp(self):
        """Get CPU temperature from LibreHardwareMonitor WMI"""
        # Try LibreHardwareMonitor first
        try:
            import pythoncom
            import wmi
            pythoncom.CoInitialize()
            w = wmi.WMI(namespace="root\\LibreHardwareMonitor")
            
            temperature_infos = w.Sensor()
            cpu_temps = []
            
            for sensor in temperature_infos:
                if sensor.SensorType == 'Temperature':
                    name = sensor.Name
                    parent = sensor.Parent
                    # Match CPU sensors from AMD or Intel CPUs by parent hardware path
                    if '/amdcpu/' in parent or '/intelcpu/' in parent or '/cpu/' in parent:
                        # Include all CPU temperature sensors
                        if any(keyword in name for keyword in ['Core', 'Tctl', 'Tdie', 'Package', 'CPU']):
                            cpu_temps.append(sensor.Value)
            
            pythoncom.CoUninitialize()
            
            if cpu_temps:
                return round(max(cpu_temps), 1)
        except:
            pass
        
        # Fallback methods if LibreHardwareMonitor not running
        
        try:
            # Method 1: Use NVIDIA GPU to estimate system temp (GPU hotspot often correlates with CPU)
            # This is a workaround - not actual CPU temp but gives thermal indication
            import subprocess
            result = subprocess.run(
                ['nvidia-smi', '--query-gpu=temperature.gpu', '--format=csv,noheader,nounits'],
                capture_output=True, text=True, timeout=2
            )
            if result.returncode == 0 and result.stdout.strip():
                # GPU temp can give rough system thermal status
                # Return None to indicate we'll show GPU temp instead
                pass
        except:
            pass
        
        try:
            # Method 2: Read from ASUS WMI (ATKACPI)
            import subprocess
            # Query ASUS ACPI sensors
            result = subprocess.run(
                ['powershell', '-Command',
                 '''
                 $temp = $null
                 try {
                     $wmi = Get-WmiObject -Namespace "root/WMI" -Class "AsusATK" -ErrorAction SilentlyContinue
                     if ($wmi) { $temp = $wmi.Temperature }
                 } catch {}
                 if (-not $temp) {
                     try {
                         $thermal = Get-WmiObject -Namespace "root/WMI" -Class "MSAcpi_ThermalZoneTemperature" -ErrorAction SilentlyContinue
                         if ($thermal) { 
                             $temp = [math]::Round(($thermal.CurrentTemperature / 10) - 273.15, 1)
                         }
                     } catch {}
                 }
                 $temp
                 '''],
                capture_output=True, text=True, timeout=3
            )
            if result.returncode == 0 and result.stdout.strip():
                try:
                    temp = float(result.stdout.strip())
                    if 0 < temp < 150:
                        return temp
                except:
                    pass
        except:
            pass
        
        try:
            # Method 3: Try psutil sensors
            temps = psutil.sensors_temperatures()
            if temps:
                for name, entries in temps.items():
                    for entry in entries:
                        if 'cpu' in name.lower() or 'core' in entry.label.lower() or 'package' in entry.label.lower():
                            return entry.current
        except:
            pass
        
        # Method 4: Return GPU temp as system thermal indicator if nothing else works
        gpu_info = self.get_gpu_info()
        if gpu_info and gpu_info.get('temp'):
            return None  # Return None, we'll show "Use GPU temp" message
        
        return None
    
    def format_bytes(self, bytes_value):
        """Format bytes to human readable"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_value < 1024.0:
                return f"{bytes_value:.2f} {unit}"
            bytes_value /= 1024.0
        return f"{bytes_value:.2f} PB"
    
    def update_system_info(self):
        """Update system information"""
        hostname = platform.node()
        system = platform.system()
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        info = f"🖥️ {hostname} | {system} | ⏰ {timestamp}"
        self.system_label.config(text=info)
    
    def update_cpu(self):
        """Update CPU information"""
        cpu_percent = psutil.cpu_percent(interval=1)
        cpu_count = psutil.cpu_count()
        cpu_freq = psutil.cpu_freq()
        cpu_per_core = psutil.cpu_percent(interval=0, percpu=True)
        cpu_temp = self.get_cpu_temp()
        
        # Update progress bar
        self.cpu_progress['value'] = cpu_percent
        
        # Update label - show GPU temp as reference if CPU temp not available
        gpu_info = self.get_gpu_info()
        if cpu_temp:
            temp_str = f" | Temp: {cpu_temp:.1f}°C"
        elif gpu_info and gpu_info.get('temp'):
            temp_str = f" | System Thermal (GPU): {gpu_info['temp']:.1f}°C"
        else:
            temp_str = " | Temp: N/A"
        self.cpu_usage_label.config(text=f"CPU Usage: {cpu_percent}%{temp_str}")
        
        # Update details with table format
        details = "╔══════════════════════════════════════════════════════════════╗\n"
        details += "║                      CPU INFORMATION                         ║\n"
        details += "╠══════════════════════════════════════════════════════════════╣\n"
        details += f"║  {'Metric':<25} │ {'Value':<32} ║\n"
        details += "╠══════════════════════════════════════════════════════════════╣\n"
        details += f"║  {'Overall Usage':<25} │ {cpu_percent:>6.1f} %{'':<24} ║\n"
        details += f"║  {'Physical Cores':<25} │ {psutil.cpu_count(logical=False):>6}{'':<25} ║\n"
        details += f"║  {'Logical Cores':<25} │ {cpu_count:>6}{'':<25} ║\n"
        
        if cpu_temp:
            details += f"║  {'Temperature':<25} │ {cpu_temp:>6.1f} °C{'':<23} ║\n"
        elif gpu_info and gpu_info.get('temp'):
            details += f"║  {'System Thermal (GPU)':<25} │ {gpu_info['temp']:>6.1f} °C{'':<23} ║\n"
        else:
            details += f"║  {'Temperature':<25} │ {'N/A':>6}{'':<25} ║\n"
        
        if cpu_freq:
            details += f"║  {'Current Frequency':<25} │ {cpu_freq.current:>6.0f} MHz{'':<22} ║\n"
            details += f"║  {'Max Frequency':<25} │ {cpu_freq.max:>6.0f} MHz{'':<22} ║\n"
        
        details += "╠══════════════════════════════════════════════════════════════╣\n"
        details += "║                      PER-CORE USAGE                          ║\n"
        details += "╠══════════════════════════════════════════════════════════════╣\n"
        
        for i in range(0, len(cpu_per_core), 4):
            row = ""
            for j in range(4):
                if i + j < len(cpu_per_core):
                    bar = self.get_bar(cpu_per_core[i+j], 8)
                    row += f"Core {i+j:2d}: {bar} {cpu_per_core[i+j]:5.1f}%  "
            details += f"║  {row:<60} ║\n"
        
        details += "╚══════════════════════════════════════════════════════════════╝\n"
        
        self.cpu_details.delete(1.0, tk.END)
        self.cpu_details.insert(1.0, details)
    
    def get_bar(self, percent, length=10):
        """Create a progress bar string"""
        filled = int(percent / 100 * length)
        bar = '█' * filled + '░' * (length - filled)
        return bar
    
    def update_memory(self):
        """Update memory information"""
        mem = psutil.virtual_memory()
        swap = psutil.swap_memory()
        
        # Update progress bar
        self.memory_progress['value'] = mem.percent
        
        # Update label
        self.memory_label.config(text=f"RAM Usage: {mem.percent}%")
        
        # Update details with table format
        details = "╔══════════════════════════════════════════════════════════════╗\n"
        details += "║                     MEMORY INFORMATION                       ║\n"
        details += "╠══════════════════════════════════════════════════════════════╣\n"
        details += f"║  {'Metric':<20} │ {'Value':<18} │ {'Bar':<16} ║\n"
        details += "╠══════════════════════════════════════════════════════════════╣\n"
        details += "║                          RAM                                 ║\n"
        details += "╠══════════════════════════════════════════════════════════════╣\n"
        details += f"║  {'Total':<20} │ {self.format_bytes(mem.total):>18} │ {'':<16} ║\n"
        details += f"║  {'Used':<20} │ {self.format_bytes(mem.used):>18} │ {self.get_bar(mem.percent, 14):<16} ║\n"
        details += f"║  {'Available':<20} │ {self.format_bytes(mem.available):>18} │ {'':<16} ║\n"
        details += f"║  {'Usage':<20} │ {mem.percent:>17.1f}% │ {'':<16} ║\n"
        details += "╠══════════════════════════════════════════════════════════════╣\n"
        details += "║                      SWAP / PAGE FILE                        ║\n"
        details += "╠══════════════════════════════════════════════════════════════╣\n"
        details += f"║  {'Total':<20} │ {self.format_bytes(swap.total):>18} │ {'':<16} ║\n"
        details += f"║  {'Used':<20} │ {self.format_bytes(swap.used):>18} │ {self.get_bar(swap.percent, 14):<16} ║\n"
        details += f"║  {'Free':<20} │ {self.format_bytes(swap.free):>18} │ {'':<16} ║\n"
        details += f"║  {'Usage':<20} │ {swap.percent:>17.1f}% │ {'':<16} ║\n"
        details += "╚══════════════════════════════════════════════════════════════╝\n"
        
        self.memory_details.delete(1.0, tk.END)
        self.memory_details.insert(1.0, details)
    
    def update_disk(self):
        """Update disk information"""
        details = ""
        
        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                details += f"Drive: {partition.device}\n"
                details += f"  Mountpoint: {partition.mountpoint}\n"
                details += f"  File System: {partition.fstype}\n"
                details += f"  Total:  {self.format_bytes(usage.total)}\n"
                details += f"  Used:   {self.format_bytes(usage.used)}\n"
                details += f"  Free:   {self.format_bytes(usage.free)}\n"
                details += f"  Percent: {usage.percent}%\n"
                details += "-" * 60 + "\n"
            except:
                pass
        
        # Disk I/O
        disk_io = psutil.disk_io_counters()
        if disk_io:
            details += f"\nDisk I/O:\n"
            details += f"  Read:    {self.format_bytes(disk_io.read_bytes)}\n"
            details += f"  Write:   {self.format_bytes(disk_io.write_bytes)}\n"
        
        self.disk_details.delete(1.0, tk.END)
        self.disk_details.insert(1.0, details)
    
    def update_network(self):
        """Update network information"""
        net_io = psutil.net_io_counters()
        
        details = f"Network Statistics:\n"
        details += f"  Bytes Sent:     {self.format_bytes(net_io.bytes_sent)}\n"
        details += f"  Bytes Received: {self.format_bytes(net_io.bytes_recv)}\n"
        details += f"  Packets Sent:   {net_io.packets_sent:,}\n"
        details += f"  Packets Recv:   {net_io.packets_recv:,}\n"
        details += f"  Errors In:      {net_io.errin:,}\n"
        details += f"  Errors Out:     {net_io.errout:,}\n"
        details += f"  Drops In:       {net_io.dropin:,}\n"
        details += f"  Drops Out:      {net_io.dropout:,}\n\n"
        
        details += "Network Interfaces:\n"
        details += "-" * 60 + "\n"
        
        for interface, addrs in psutil.net_if_addrs().items():
            details += f"{interface}:\n"
            for addr in addrs:
                if addr.family == 2:  # IPv4
                    details += f"  IPv4: {addr.address}\n"
        
        self.network_details.delete(1.0, tk.END)
        self.network_details.insert(1.0, details)
    
    def update_gpu(self):
        """Update GPU information with all metrics"""
        gpu_info = self.get_gpu_info()
        
        if gpu_info:
            details = f"GPU: {gpu_info['name']}\n"
            details += "=" * 60 + "\n\n"
            
            # Temperature
            temp_emoji = "🟢" if gpu_info['temp'] < 70 else "🟡" if gpu_info['temp'] < 85 else "🔴"
            details += f"🌡️  Temperature:       {temp_emoji} {gpu_info['temp']:.1f}°C\n\n"
            
            # Utilization
            util_emoji = "🟢" if gpu_info['util'] < 50 else "🟡" if gpu_info['util'] < 80 else "🔴"
            details += f"⚡ GPU Utilization:   {util_emoji} {gpu_info['util']:.1f}%\n"
            
            mem_util_emoji = "🟢" if gpu_info['mem_util'] < 50 else "🟡" if gpu_info['mem_util'] < 80 else "🔴"
            details += f"💾 Memory Utilization: {mem_util_emoji} {gpu_info['mem_util']:.1f}%\n\n"
            
            # Memory
            mem_percent = (gpu_info['mem_used'] / gpu_info['mem_total'] * 100) if gpu_info['mem_total'] > 0 else 0
            mem_emoji = "🟢" if mem_percent < 50 else "🟡" if mem_percent < 80 else "🔴"
            details += f"📊 Memory Used:       {mem_emoji} {gpu_info['mem_used']:.0f} MB / {gpu_info['mem_total']:.0f} MB\n"
            details += f"   Memory Usage:      {mem_percent:.1f}%\n\n"
            
            # Power
            power_percent = (gpu_info['power_draw'] / gpu_info['power_limit'] * 100) if gpu_info['power_limit'] > 0 else 0
            power_emoji = "🟢" if power_percent < 70 else "🟡" if power_percent < 90 else "🔴"
            details += f"🔋 Power Draw:        {power_emoji} {gpu_info['power_draw']:.1f} W / {gpu_info['power_limit']:.1f} W\n"
            details += f"   Power Usage:       {power_percent:.1f}%\n\n"
            
            # Clocks
            details += f"🕐 GPU Clock:         {gpu_info['clock_gpu']:.0f} MHz\n"
            details += f"🕐 Memory Clock:      {gpu_info['clock_mem']:.0f} MHz\n\n"
            
            # Fan
            fan_emoji = "🟢" if gpu_info['fan_speed'] < 60 else "🟡" if gpu_info['fan_speed'] < 80 else "🔴"
            details += f"💨 Fan Speed:         {fan_emoji} {gpu_info['fan_speed']:.0f}%\n"
        else:
            details = "No GPU detected or nvidia-smi not available\n\n"
            details += "For NVIDIA GPUs, install NVIDIA drivers with nvidia-smi utility.\n\n"
            details += "Note: GPU metrics showing 0 MB may indicate the GPU is idle\n"
            details += "or nvidia-smi needs to be run with proper permissions."
        
        self.gpu_details.delete(1.0, tk.END)
        self.gpu_details.insert(1.0, details)
    
    def update_loop(self):
        """Background thread to update all metrics"""
        while self.running:
            try:
                self.root.after(0, self.update_system_info)
                self.root.after(0, self.update_cpu)
                self.root.after(0, self.update_memory)
                self.root.after(0, self.update_disk)
                self.root.after(0, self.update_network)
                self.root.after(0, self.update_gpu)
                
                self.root.after(0, lambda: self.status_bar.config(
                    text=f"Last updated: {datetime.now().strftime('%H:%M:%S')} | Refreshing every 2 seconds"))
                
                time.sleep(2)
            except Exception as e:
                print(f"Update error: {e}")
                break
    
    def on_closing(self):
        """Handle window closing"""
        self.running = False
        self.root.destroy()

def main():
    root = tk.Tk()
    app = SystemMonitorGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()
