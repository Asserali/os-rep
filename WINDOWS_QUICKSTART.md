# Quick Start Guide - Windows

## ✅ System Monitor is Ready to Run!

You have successfully set up the system monitor on Windows.

### Current Status
- ✅ Python 3.12.10 installed
- ✅ psutil library installed
- ✅ Monitoring script working
- ✅ Data collection successful

### Quick Commands

#### 1. Run Monitoring (Simple Python Version)
```cmd
python monitor_windows.py
```
This will:
- Collect CPU, memory, disk, and network metrics
- Display results in console
- Save to `data/metrics/latest.json`

#### 2. Run Monitoring (Double-click method)
Just double-click: **`run_monitor.bat`**

#### 3. View Your Data
Open the JSON file:
```cmd
notepad data\metrics\latest.json
```

### Advanced: Web Dashboard

If you want the beautiful web dashboard, install additional packages:

```cmd
pip install flask plotly jinja2 markdown pandas
```

Then run:
```cmd
python reporting/reporter.py
```

Access the web dashboard at: **http://localhost:8080**

### What the Monitor Shows

- **💻 CPU**: Usage percentage, cores, frequency
- **💾 Memory**: RAM usage, available memory
- **💿 Swap**: Page file usage (Windows)
- **📀 Disk**: All drives (C:, D:, etc.) with usage
- **🌐 Network**: Data sent/received, packets

### Files Created

- `monitor_windows.py` - Simple Python monitoring script
- `run_monitor.bat` - Windows batch file for easy execution
- `data/metrics/latest.json` - Your latest metrics

### Need Help?

**Issue**: Python not found
**Solution**: Download from https://www.python.org/

**Issue**: Package install fails
**Solution**: Run as administrator or use:
```cmd
pip install --user psutil
```

**Issue**: Want the full Bash version
**Solution**: Install Git Bash from https://git-scm.com/

---

**Enjoy monitoring your system!** 🎉
