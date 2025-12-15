# How to Enable CPU Temperature Monitoring on Windows

The GUI now supports CPU temperature monitoring, but Windows requires additional software to access temperature sensors.

## Option 1: LibreHardwareMonitor (Recommended)

1. **Download LibreHardwareMonitor:**
   - Visit: https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases
   - Download the latest release (e.g., `LibreHardwareMonitor-net472.zip`)

2. **Extract and Run:**
   - Extract the ZIP file to a folder (e.g., `C:\Program Files\LibreHardwareMonitor`)
   - Right-click `LibreHardwareMonitor.exe` and select "Run as Administrator"
   - Keep it running in the background

3. **Enable WMI:**
   - In LibreHardwareMonitor, go to Options → "Remote Web Server"
   - Check "Run" to enable the web server (optional)
   - The WMI interface is enabled by default when running as admin

4. **Restart the GUI:**
   - Close and reopen the System Monitor GUI
   - CPU temperature should now be displayed

## Option 2: OpenHardwareMonitor (Alternative)

1. **Download OpenHardwareMonitor:**
   - Visit: https://openhardwaremonitor.org/downloads/
   - Download the latest version

2. **Extract and Run:**
   - Extract to a folder
   - Right-click `OpenHardwareMonitor.exe` and select "Run as Administrator"

3. **Restart the GUI:**
   - Temperature data will be available via WMI

## Verification

After installing either tool:
1. Make sure it's running as Administrator
2. Restart the System Monitor GUI
3. Go to the CPU tab
4. You should see the temperature displayed next to CPU usage

## Troubleshooting

**Temperature shows "N/A":**
- Make sure LibreHardwareMonitor/OpenHardwareMonitor is running as Administrator
- Some laptops may not expose CPU temperature sensors
- Try both tools to see which works better with your hardware

**No temperature after installation:**
- Restart both the monitoring tool and the GUI
- Check if your CPU supports temperature monitoring
- Try running the GUI as Administrator as well

## Alternative: HWiNFO64

If the above tools don't work, you can use HWiNFO64:
1. Download from: https://www.hwinfo.com/download/
2. Run as Administrator
3. Enable "Shared Memory Support" in settings
4. The System Monitor GUI will need to be modified to read from HWiNFO's shared memory

---

**Note:** The System Monitor GUI will work without temperature monitoring, it will just show "N/A" for CPU temperature.
