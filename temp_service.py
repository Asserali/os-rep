"""
CPU Temperature HTTP Service
Exposes LibreHardwareMonitor CPU temperature via HTTP for Docker containers
"""

from flask import Flask, jsonify
import pythoncom
import wmi
import sys

app = Flask(__name__)

def get_cpu_temp():
    """Get CPU temperature from LibreHardwareMonitor"""
    try:
        pythoncom.CoInitialize()
        w = wmi.WMI(namespace="root\\LibreHardwareMonitor")
        
        cpu_temps = []
        for sensor in w.Sensor():
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
        return None
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return None

@app.route('/cpu/temperature')
def cpu_temperature():
    """Endpoint to get CPU temperature"""
    temp = get_cpu_temp()
    if temp is not None:
        return jsonify({
            'temperature': temp,
            'unit': 'celsius',
            'sensor': 'LibreHardwareMonitor'
        })
    else:
        return jsonify({
            'error': 'Temperature not available'
        }), 503

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    print("Starting CPU Temperature Service on http://localhost:5555")
    print("Endpoint: http://localhost:5555/cpu/temperature")
    app.run(host='0.0.0.0', port=5555, debug=False)
