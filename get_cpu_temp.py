"""
Temperature Provider for WSL
Reads CPU temperature from LibreHardwareMonitor and outputs it for WSL scripts
"""

import pythoncom
import wmi
import sys

try:
    pythoncom.CoInitialize()
    w = wmi.WMI(namespace="root\\LibreHardwareMonitor")
    
    cpu_temps = []
    for sensor in w.Sensor():
        if sensor.SensorType == 'Temperature':
            name = sensor.Name
            parent = sensor.Parent
            # Match CPU sensors from AMD or Intel CPUs
            if '/amdcpu/' in parent or '/intelcpu/' in parent or '/cpu/' in parent:
                # Include all CPU temperature sensors
                if any(keyword in name for keyword in ['Core', 'Tctl', 'Tdie', 'Package', 'CPU']):
                    cpu_temps.append(sensor.Value)
    
    pythoncom.CoUninitialize()
    
    if cpu_temps:
        print(round(max(cpu_temps), 1))
    else:
        print("N/A")
except:
    print("N/A")
    sys.exit(1)
