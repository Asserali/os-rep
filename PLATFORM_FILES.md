# Platform-Specific Files Reference

This document lists all platform-specific files for Solution 1.

---

## 📁 Core Files (All Platforms)

| File | Platform | Description |
|------|----------|-------------|
| `docker/Dockerfile.dashboard` | All | Dashboard container image |
| `docker-compose-solution1.yml` | All | Container orchestration |
| `requirements-dashboard.txt` | All | Dashboard Python dependencies |
| `reporting/reporter.py` | All | Flask web server |
| `reporting/templates/dashboard.html` | All | Web UI |

---

## 🪟 Windows Files

| File | Description |
|------|-------------|
| `monitor_windows.py` | Native Windows metrics collector |
| `run_solution1.bat` | One-click start script |
| `windows_service.py` | Windows Service wrapper (optional) |
| `install-windows-agent.ps1` | Service installer (optional) |
| `start-solution1.bat` | Service + Dashboard starter (optional) |

**Quick Start:**
```cmd
.\run_solution1.bat
```

**Output File:** `data/metrics/latest_windows.json`

---

## 🐧 Linux Files

| File | Description |
|------|-------------|
| `monitor_linux.py` | Native Linux metrics collector |
| `run_solution1.sh` | One-click start script |
| `stop_solution1.sh` | Stop script |

**Quick Start:**
```bash
chmod +x run_solution1.sh
./run_solution1.sh
```

**Output File:** `data/metrics/latest_linux.json`

**Features:**
- ✅ CPU temperature via sensors/thermal zones
- ✅ GPU support via nvidia-smi
- ✅ Load average from /proc
- ✅ Process monitoring
- ✅ Disk, memory, network stats

---

## 🍎 macOS Files

| File | Description |
|------|-------------|
| `monitor_mac.py` | Native macOS metrics collector |
| `run_solution1.sh` | One-click start script (shared with Linux) |
| `stop_solution1.sh` | Stop script (shared with Linux) |

**Quick Start:**
```bash
chmod +x run_solution1.sh
./run_solution1.sh
```

**Output File:** `data/metrics/latest_mac.json`

**Features:**
- ✅ CPU temperature via osx-cpu-temp (optional)
- ✅ GPU detection via system_profiler
- ✅ Load average from macOS APIs
- ✅ Process monitoring
- ✅ Disk, memory, network stats

**Optional Dependencies:**
```bash
# For CPU temperature
brew install osx-cpu-temp
```

---

## 🐳 Docker Container (Shared)

The dashboard container is **platform-independent** and works on all OSes:

```bash
docker pull <username>/system-monitor-dashboard:latest
```

**Volume Mount:**
- Windows: `-v ${PWD}/data:/data:ro`
- Linux/Mac: `-v $(pwd)/data:/data:ro`

**Reads:**
- Windows: `latest_windows.json`
- Linux: `latest_linux.json`
- macOS: `latest_mac.json`

---

## 📊 Metrics File Format

All platform collectors output the same JSON structure:

```json
{
  "timestamp": "2025-12-15T00:00:00",
  "system": {
    "hostname": "...",
    "platform": "Windows|Linux|Darwin",
    "version": "...",
    "architecture": "..."
  },
  "cpu": {
    "usage_percent": 15.0,
    "count": 16,
    "frequency_mhz": 4001,
    "temperature": 65.5
  },
  "memory": { ... },
  "swap": { ... },
  "disk": [ ... ],
  "network": { ... },
  "gpu": { ... },
  "system_load": { ... }
}
```

---

## 🚀 Running on Different Platforms

### Windows
```powershell
# Dependencies
pip install psutil wmi

# Run
.\run_solution1.bat

# Access
http://localhost:8080
```

### Linux
```bash
# Dependencies
pip3 install psutil

# Run
chmod +x run_solution1.sh
./run_solution1.sh

# Access
http://localhost:8080
```

### macOS
```bash
# Dependencies
pip3 install psutil
brew install osx-cpu-temp  # Optional for CPU temp

# Run
chmod +x run_solution1.sh
./run_solution1.sh

# Access
http://localhost:8080
```

---

## 🔄 Platform Detection

The `run_solution1.sh` script **automatically detects** the platform:

```bash
PLATFORM=$(uname)
if [ "$PLATFORM" == "Darwin" ]; then
    MONITOR_SCRIPT="monitor_mac.py"
elif [ "$PLATFORM" == "Linux" ]; then
    MONITOR_SCRIPT="monitor_linux.py"
fi
```

So the same `run_solution1.sh` works on both Linux and macOS!

---

## 📝 Summary

| Platform | Collector | Runner | Output |
|----------|-----------|--------|--------|
| Windows | `monitor_windows.py` | `run_solution1.bat` | `latest_windows.json` |
| Linux | `monitor_linux.py` | `run_solution1.sh` | `latest_linux.json` |
| macOS | `monitor_mac.py` | `run_solution1.sh` | `latest_mac.json` |
| **Dashboard** | **Same Docker image for all** | **Same container** | **Reads all formats** |

**Total files needed per platform:**
- Windows: 2 files (monitor_windows.py + run_solution1.bat)
- Linux: 2 files (monitor_linux.py + run_solution1.sh)
- macOS: 2 files (monitor_mac.py + run_solution1.sh)
- Dashboard: 1 Docker image (works everywhere)

**That's it!** 🎉
