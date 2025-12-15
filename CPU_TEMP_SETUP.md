# Real CPU Temperature Monitoring Setup

## What Was Installed

LibreHardwareMonitor has been downloaded and configured to provide **real ASUS CPU temperature** monitoring.

## How to Use

### Option 1: Windows GUI with Real CPU Temps (RECOMMENDED)

Double-click: **`start_monitor_with_temps.bat`**

This will:
1. Request admin privileges (required for hardware monitoring)
2. Start LibreHardwareMonitor in the background
3. Launch the GUI with real CPU temperatures

### Option 2: WSL Bash Script with Real CPU Temps

In WSL terminal, run:
```bash
./monitor_wsl.sh
```

The script now reads CPU temperature from LibreHardwareMonitor running in Windows.

### Option 3: Manual LibreHardwareMonitor Start

If you want to start LibreHardwareMonitor separately:

Double-click: **`LibreHardwareMonitor\LibreHardwareMonitor.exe`**
- Right-click → Run as Administrator
- Minimize it to system tray
- Then run any monitor script

## Technical Details

### Files Created:
- `LibreHardwareMonitor/` - Hardware monitoring software
- `hwmonitor_service.py` - Python service to start and query LibreHardwareMonitor
- `get_cpu_temp.py` - Temperature provider for WSL scripts
- `start_monitor_with_temps.bat` - One-click launcher with auto-elevation
- `start_hwmonitor_admin.vbs` - Admin launcher for LibreHardwareMonitor

### How It Works:
1. LibreHardwareMonitor runs with admin rights to access ASUS thermal sensors
2. It exposes temperature data via WMI namespace `root\LibreHardwareMonitor`
3. Python scripts query this WMI namespace to get real CPU Package temperature
4. WSL scripts call Windows Python to bridge the gap

### Temperature Sources:
- **CPU Package**: Overall CPU temperature (max of all cores)
- **CPU Cores**: Individual core temperatures
- **GPU**: NVIDIA GPU temperature (separate metric)

## Troubleshooting

**No temperature showing?**
- Make sure LibreHardwareMonitor is running as Administrator
- Wait 3-5 seconds after starting for sensors to initialize
- Check Windows Task Manager → Details → LibreHardwareMonitor.exe should be running

**WSL shows "N/A"?**
- LibreHardwareMonitor must be running in Windows first
- The WSL script calls back to Windows Python to get the temperature

**GUI shows old temperature?**
- Close and restart using `start_monitor_with_temps.bat`
- This ensures LibreHardwareMonitor is fresh

## What You Get

✅ **Real ASUS CPU temperature** (same as MyASUS app shows)
✅ **Real-time updates** (not cached like Windows WMI)
✅ **Works in both Windows GUI and WSL bash**
✅ **All CPU cores monitored**
✅ **GPU metrics separate from CPU**
