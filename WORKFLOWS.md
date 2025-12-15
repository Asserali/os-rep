# Complete Workflows - All Platforms

This document provides the complete workflow for deploying Solution 1 on Windows, Linux, and macOS.

---

## 📦 Files Created

### Platform-Specific Collectors
- ✅ **monitor_windows.py** - Windows metrics collector (psutil + WMI)
- ✅ **monitor_linux.py** - Linux metrics collector (psutil + sensors + nvidia-smi)
- ✅ **monitor_mac.py** - macOS metrics collector (psutil + system_profiler + osx-cpu-temp)

### Platform-Specific Run Scripts
- ✅ **run_solution1.bat** - Windows one-click start
- ✅ **run_solution1.sh** - Linux/macOS one-click start (auto-detects platform)
- ✅ **stop_solution1.sh** - Linux/macOS stop script

### Shared Dashboard (All Platforms)
- ✅ **docker/Dockerfile.dashboard** - Container image
- ✅ **docker-compose-solution1.yml** - Container orchestration
- ✅ **reporting/reporter.py** - Flask web server
- ✅ **reporting/templates/dashboard.html** - Web UI

---

## 🪟 Windows Workflow

### Prerequisites
```powershell
# Check Python
python --version  # Should be 3.11+

# Check Docker
docker --version

# Install dependencies
pip install psutil wmi
```

### Quick Start
```cmd
.\run_solution1.bat
```

### What Happens
1. ✅ Starts dashboard container (port 8080)
2. ✅ Starts background PowerShell window (minimized)
3. ✅ Collects metrics every 5 seconds
4. ✅ Opens browser to http://localhost:8080

### Manual Steps
```powershell
# 1. Start dashboard
docker-compose -f docker-compose-solution1.yml up -d

# 2. Start metrics collection
while ($true) { python monitor_windows.py; Start-Sleep -Seconds 5 }
```

### Stop
```powershell
# Stop dashboard
docker-compose -f docker-compose-solution1.yml down

# Stop metrics: Close minimized PowerShell window
```

### Output
- **Metrics File:** `data/metrics/latest_windows.json`
- **Dashboard:** http://localhost:8080

---

## 🐧 Linux Workflow

### Prerequisites
```bash
# Check Python
python3 --version  # Should be 3.7+

# Check Docker
docker --version

# Install dependencies
pip3 install psutil

# Optional: For temperature monitoring
# Ubuntu/Debian:
sudo apt-get install lm-sensors
sudo sensors-detect

# Fedora/RHEL:
sudo dnf install lm_sensors
```

### Quick Start
```bash
chmod +x run_solution1.sh
./run_solution1.sh
```

### What Happens
1. ✅ Detects platform as Linux
2. ✅ Starts dashboard container (port 8080)
3. ✅ Starts background metrics collection
4. ✅ Saves PID to `.monitor.pid`
5. ✅ Opens browser to http://localhost:8080

### Manual Steps
```bash
# 1. Start dashboard
docker-compose -f docker-compose-solution1.yml up -d

# 2. Start metrics collection in background
nohup bash -c "while true; do python3 monitor_linux.py >/dev/null 2>&1; sleep 5; done" &
```

### Stop
```bash
./stop_solution1.sh

# Or manually:
docker-compose -f docker-compose-solution1.yml down
kill $(cat .monitor.pid)
```

### Output
- **Metrics File:** `data/metrics/latest_linux.json`
- **Dashboard:** http://localhost:8080
- **PID File:** `.monitor.pid`

### Features
- ✅ CPU temperature from `/sys/class/thermal` or `sensors`
- ✅ GPU monitoring via `nvidia-smi`
- ✅ Load average from `os.getloadavg()`
- ✅ Process monitoring via `psutil`
- ✅ Disk usage (excludes tmpfs, devfs, etc.)

---

## 🍎 macOS Workflow

### Prerequisites
```bash
# Check Python
python3 --version  # Should be 3.7+

# Check Docker
docker --version

# Install dependencies
pip3 install psutil

# Optional: For CPU temperature
brew install osx-cpu-temp
```

### Quick Start
```bash
chmod +x run_solution1.sh
./run_solution1.sh
```

### What Happens
1. ✅ Detects platform as macOS (Darwin)
2. ✅ Starts dashboard container (port 8080)
3. ✅ Starts background metrics collection
4. ✅ Saves PID to `.monitor.pid`
5. ✅ Opens browser via `open` command

### Manual Steps
```bash
# 1. Start dashboard
docker-compose -f docker-compose-solution1.yml up -d

# 2. Start metrics collection in background
nohup bash -c "while true; do python3 monitor_mac.py >/dev/null 2>&1; sleep 5; done" &
```

### Stop
```bash
./stop_solution1.sh

# Or manually:
docker-compose -f docker-compose-solution1.yml down
kill $(cat .monitor.pid)
```

### Output
- **Metrics File:** `data/metrics/latest_mac.json`
- **Dashboard:** http://localhost:8080
- **PID File:** `.monitor.pid`

### Features
- ✅ CPU temperature via `osx-cpu-temp` (if installed)
- ✅ GPU detection via `system_profiler`
- ✅ Load average from `os.getloadavg()`
- ✅ Process monitoring via `psutil`
- ✅ macOS-specific filesystem filtering

---

## 🐳 Docker Dashboard (All Platforms)

The dashboard container is **platform-independent** and identical on all OSes.

### Container Details
- **Image:** `system-monitor-dashboard:latest`
- **Port:** 8080
- **Volume:** `./data:/data:ro` (read-only)
- **Health Check:** `curl -f http://localhost:8080/health`

### Supported Metrics Files
The dashboard automatically detects and displays:
- `latest_windows.json` (Windows metrics)
- `latest_linux.json` (Linux metrics)
- `latest_mac.json` (macOS metrics)
- `latest_wsl.json` (WSL/Docker metrics)

### API Endpoints
- `GET /` - Dashboard UI
- `GET /health` - Health check (returns JSON)
- `GET /api/charts` - Chart data (404 for now, future feature)

---

## 📊 Metrics Comparison

| Feature | Windows | Linux | macOS |
|---------|---------|-------|-------|
| **CPU Usage** | ✅ psutil | ✅ psutil | ✅ psutil |
| **CPU Temp** | ✅ LibreHardwareMonitor | ✅ sensors/thermal | ⚠️ osx-cpu-temp (optional) |
| **Memory** | ✅ psutil | ✅ psutil | ✅ psutil |
| **Disk** | ✅ All drives | ✅ Filtered partitions | ✅ Filtered partitions |
| **Network** | ✅ psutil | ✅ psutil | ✅ psutil |
| **GPU** | ✅ WMI + nvidia-smi | ✅ nvidia-smi | ⚠️ system_profiler (basic) |
| **Load Avg** | ✅ Calculated | ✅ os.getloadavg() | ✅ os.getloadavg() |
| **Processes** | ✅ psutil | ✅ psutil | ✅ psutil |

**Legend:**
- ✅ Fully supported
- ⚠️ Optional or limited support
- ❌ Not supported

---

## 🔄 Deployment Workflow

### 1️⃣ For Users Pulling Docker Image

**All Platforms Need:**
```bash
# 1. Pull dashboard image
docker pull <username>/system-monitor-dashboard:latest

# 2. Download platform-specific collector
# - Windows: monitor_windows.py
# - Linux: monitor_linux.py
# - macOS: monitor_mac.py

# 3. Install dependencies
# Windows: pip install psutil wmi
# Linux: pip3 install psutil
# macOS: pip3 install psutil

# 4. Run
# Windows: .\run_solution1.bat
# Linux/Mac: ./run_solution1.sh
```

### 2️⃣ For Developers

**Build and Test:**
```bash
# Build dashboard image
docker build -f docker/Dockerfile.dashboard -t system-monitor-dashboard .

# Test on Windows
.\run_solution1.bat

# Test on Linux/Mac
./run_solution1.sh

# Verify metrics
curl http://localhost:8080/health
```

**Publish to Docker Hub:**
```bash
docker login
docker tag system-monitor-dashboard:latest <username>/system-monitor-dashboard:latest
docker push <username>/system-monitor-dashboard:latest
```

---

## 📝 File Summary

### Windows (2 files + Docker)
- `monitor_windows.py` - Collector
- `run_solution1.bat` - Runner
- Docker image - Dashboard

### Linux (2 files + Docker)
- `monitor_linux.py` - Collector
- `run_solution1.sh` - Runner
- Docker image - Dashboard

### macOS (2 files + Docker)
- `monitor_mac.py` - Collector  
- `run_solution1.sh` - Runner (same as Linux)
- Docker image - Dashboard

**Total unique files needed per user:**
- 2 platform-specific files
- 1 Docker image (same for all)

---

## 🎯 Next Steps

1. ✅ **Windows workflow** - Complete and tested
2. ✅ **Linux workflow** - Scripts created, ready for testing
3. ✅ **macOS workflow** - Scripts created, ready for testing
4. ⏳ **Docker Hub publish** - Waiting for username/repo
5. ⏳ **Testing** - Need to test on actual Linux/Mac systems

---

## 📚 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment guide
- **[QUICKSTART.md](QUICKSTART.md)** - Quick start for Docker Hub users
- **[PLATFORM_FILES.md](PLATFORM_FILES.md)** - File reference by platform
- **[SOLUTION1_README.md](SOLUTION1_README.md)** - Solution 1 overview

---

**All platforms are now supported!** 🎉🚀
