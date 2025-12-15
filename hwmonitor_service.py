"""
LibreHardwareMonitor Service Integration
Starts LibreHardwareMonitor and provides an API to query sensor data
"""

import subprocess
import time
import os
import sys
import pythoncom
import wmi

class HardwareMonitor:
    def __init__(self):
        self.process = None
        self.lhm_path = os.path.join(os.path.dirname(__file__), "LibreHardwareMonitor", "LibreHardwareMonitor.exe")
        
    def start(self):
        """Start LibreHardwareMonitor in background"""
        if not os.path.exists(self.lhm_path):
            raise FileNotFoundError(f"LibreHardwareMonitor not found at {self.lhm_path}")
        
        # Check if already running
        try:
            subprocess.run(['tasklist', '/FI', 'IMAGENAME eq LibreHardwareMonitor.exe'], 
                         capture_output=True, text=True, check=True)
            result = subprocess.run(['tasklist', '/FI', 'IMAGENAME eq LibreHardwareMonitor.exe'], 
                                  capture_output=True, text=True)
            if 'LibreHardwareMonitor.exe' in result.stdout:
                print("LibreHardwareMonitor already running")
                return
        except:
            pass
        
        # Start minimized
        startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startupinfo.wShowWindow = 6  # SW_MINIMIZE
        
        self.process = subprocess.Popen(
            [self.lhm_path],
            startupinfo=startupinfo,
            creationflags=subprocess.CREATE_NEW_CONSOLE
        )
        
        # Wait for WMI namespace to initialize
        print("Starting LibreHardwareMonitor...")
        time.sleep(3)
        print("LibreHardwareMonitor started")
    
    def get_cpu_temp(self):
        """Get CPU temperature from LibreHardwareMonitor WMI"""
        try:
            pythoncom.CoInitialize()
            w = wmi.WMI(namespace="root\\LibreHardwareMonitor")
            
            temperature_infos = w.Sensor()
            cpu_temps = []
            
            for sensor in temperature_infos:
                if sensor.SensorType == 'Temperature' and 'CPU' in sensor.Name:
                    if 'Package' in sensor.Name or 'Core' in sensor.Name:
                        cpu_temps.append(sensor.Value)
            
            if cpu_temps:
                return round(max(cpu_temps), 1)  # Return max temperature
            
            return None
        except Exception as e:
            print(f"Error reading CPU temp: {e}")
            return None
        finally:
            pythoncom.CoUninitialize()
    
    def get_all_temps(self):
        """Get all temperature sensors"""
        try:
            pythoncom.CoInitialize()
            w = wmi.WMI(namespace="root\\LibreHardwareMonitor")
            
            temps = {}
            for sensor in w.Sensor():
                if sensor.SensorType == 'Temperature':
                    temps[sensor.Name] = sensor.Value
            
            return temps
        except Exception as e:
            print(f"Error reading temps: {e}")
            return {}
        finally:
            pythoncom.CoUninitialize()
    
    def stop(self):
        """Stop LibreHardwareMonitor"""
        try:
            subprocess.run(['taskkill', '/F', '/IM', 'LibreHardwareMonitor.exe'], 
                         capture_output=True)
        except:
            pass

if __name__ == "__main__":
    monitor = HardwareMonitor()
    monitor.start()
    
    print("\nWaiting for sensors to initialize...")
    time.sleep(2)
    
    print("\n=== All Temperature Sensors ===")
    temps = monitor.get_all_temps()
    for name, value in temps.items():
        print(f"{name}: {value}°C")
    
    print(f"\n=== CPU Temperature ===")
    cpu_temp = monitor.get_cpu_temp()
    if cpu_temp:
        print(f"CPU: {cpu_temp}°C")
    else:
        print("CPU temperature not available")
    
    print("\nLibreHardwareMonitor is running in the background.")
    print("You can now use monitor_gui.py or monitor_wsl.sh to see temperatures.")
