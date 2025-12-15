# 🚀 Deployment Guide - Solution 1

## For New Users (Pulling the Docker Image)

This guide explains how to deploy the System Monitor on any machine after pulling the Docker image.

---

## 📋 Prerequisites

- **Docker Desktop** installed and running
- **Python 3.11+** installed
- **Git** (optional, to clone the repository)

---

## 🪟 Windows Deployment

### Step 1: Get the Required Files

**Option A: Clone Repository (Recommended)**
```powershell
git clone <repository-url>
cd system-monitor
```

**Option B: Manual Setup**
Create this folder structure:
```
system-monitor/
├── data/
│   └── metrics/
├── monitor_windows.py
└── docker-compose-solution1.yml
```

### Step 2: Install Python Dependencies
```powershell
pip install psutil wmi
```

### Step 3: Pull the Docker Image
```powershell
# Pull from Docker Hub (once published)
docker pull <your-dockerhub-username>/system-monitor-dashboard:latest

# Update docker-compose-solution1.yml to use the pulled image
```

### Step 4: Run the System

**Quick Start:**
```cmd
.\run_solution1.bat
```

**Manual Start:**
```powershell
# Start dashboard container
docker run -d --name system-monitor-dashboard `
  -p 8080:8080 `
  -v ${PWD}/data:/data:ro `
  --restart unless-stopped `
  <your-dockerhub-username>/system-monitor-dashboard:latest

# Start metrics collection (in separate window)
while ($true) { python monitor_windows.py; Start-Sleep -Seconds 5 }
```

### Step 5: Access Dashboard
Open browser: **http://localhost:8080**

---

## 🐧 Linux Deployment

### Step 1: Get the Required Files
```bash
git clone <repository-url>
cd system-monitor
```

### Step 2: Install Python Dependencies
```bash
pip3 install psutil
```

### Step 3: Get Linux Metrics Collector

**Download `monitor_linux.py` from repository** - ✅ Ready to use!

Or verify it exists:
```bash
ls -la monitor_linux.py
```

**Install Python dependencies:**
```bash
pip3 install psutil
```

### Step 4: Run Solution 1

**Quick Start:**
```bash
chmod +x run_solution1.sh
./run_solution1.sh
```

**Manual Start:**
```bash
# Pull image (if not using docker-compose)
docker pull <your-dockerhub-username>/system-monitor-dashboard:latest

# Or use docker-compose
docker-compose -f docker-compose-solution1.yml up -d

# Start metrics collection in background
nohup bash -c "while true; do python3 monitor_linux.py >/dev/null 2>&1; sleep 5; done" &
```

**Stop Everything:**
```bash
chmod +x stop_solution1.sh
./stop_solution1.sh
```

### Step 5: Access Dashboard
Open browser: **http://localhost:8080**

---

## 🍎 macOS Deployment

### Step 1: Get the Required Files
```bash
git clone <repository-url>
cd system-monitor
```

### Step 2: Install Python Dependencies
```bash
pip3 install psutil
```

### Step 3: Get macOS Metrics Collector

**Download `monitor_mac.py` from repository** - ✅ Ready to use!

Or verify it exists:
```bash
ls -la monitRun Solution 1

**Quick Start:**
```bash
chmod +x run_solution1.sh
./run_solution1.sh
```

**Manual Start:**
```bash
# Pull image (if not using docker-compose)
docker pull <your-dockerhub-username>/system-monitor-dashboard:latest

# Or use docker-compose
docker-compose -f docker-compose-solution1.yml up -d

# Start metrics collection in background
nohup bash -c "while true; do python3 monitor_mac.py >/dev/null 2>&1; sleep 5; done" &
```

**Stop Everything:**
```bash
chmod +x stop_solution1.sh
./stop_solution1.sher pull <your-dockerhub-username>/system-monitor-dashboard:latest

# Run container
docker run -d --name system-monitor-dashboard \
  -p 8080:8080 \
  -v $(pwd)/data:/data:ro \
  --restart unless-stopped \
  <your-dockerhub-username>/system-monitor-dashboard:latest

# Start metrics collection
while true; do
  python3 monitor_mac.py  # When implemented
  sleep 5
done
```

### Step 5: Access Dashboard
Open browser: **http://localhost:8080**

---

## 📦 Publishing the Docker Image

### For Maintainers: How to Publish

**1. Build the Image**
```powershell
cd system-monitor
docker build -f docker/Dockerfile.dashboard -t system-monitor-dashboard:latest .
```

**2. Tag for Docker Hub**
```powershell
docker tag system-monitor-dashboard:latest <your-dockerhub-username>/system-monitor-dashboard:latest
docker tag system-monitor-dashboard:latest <your-dockerhub-username>/system-monitor-dashboard:v1.0
```

**3. Push to Docker Hub**
```powershell
docker login
docker push <your-dockerhub-username>/system-monitor-dashboard:latest
docker push <your-dockerhub-username>/system-monitor-dashboard:v1.0
```

**4. Update Documentation**
Replace `<your-dockerhub-username>` in this file with actual username.

---

## 🔧 Configuration

### Custom Metrics Interval

**Windows (run_solution1.bat):**
Change `Start-Sleep -Seconds 5` to desired interval

**Linux/Mac:**
Change `sleep 5` to desired interval

### Custom Dashboard Port

**docker-compose-solution1.yml:**
```yaml
ports:
  - "8080:8080"  # Change first port: "9000:8080"
```

**docker run command:**
```bash
-p 9000:8080  # Change 9000 to desired port
```

---

## 🛠️ Troubleshooting

### Dashboard shows "No metrics data available"

**Check metrics file exists:**
```powershell
# Windows
dir data\metrics\latest_windows.json

# Linux/Mac
ls -la data/metrics/latest_windows.json
```

**Generate metrics manually:**
```powershell
python monitor_windows.py
```

**Check container can access volume:**
```powershell
docker exec system-monitor-dashboard ls -la /data/metrics/
```

### Container not starting

**Check Docker is running:**
```powershell
docker ps
```

**View container logs:**
```powershell
docker logs system-monitor-dashboard
```

**Restart container:**
```powershell
docker restart system-monitor-dashboard
```

### Metrics not updating

**Check if metrics collection is running:**
```powershell
# Windows: Look for minimized PowerShell window
# Or check Task Manager for python.exe processes

# Linux/Mac: Check background processes
ps aux | grep monitor
```

**Restart metrics collection:**
```powershell
# Stop the background window and run again
.\run_solution1.bat
```

---

## 📊 What Gets Monitored

### Windows
- ✅ CPU usage and frequency
- ✅ Memory and swap usage
- ✅ Disk usage (all drives)
- ✅ Network statistics
- ✅ GPU usage and temperature (NVIDIA)
- ✅ System load and processes
- ✅ Real-time temperature (if LibreHardwareMonitor available)

### Linux (Coming Soon)
- CPU, memory, disk, network
- Temperature via sensors or thermal zones
- GPU via nvidia-smi
- System load from /proc
- ✅ **monitor_linux.py ready to use!**

### macOS (Coming Soon)
- CPU, memory, disk, network
- Temperature via osx-cpu-temp or powermetrics
- GPU detection via system_profiler
- System load via sysctl
- ✅ **monitor_mac.py ready to use!**

---

## 🔐 Security Notes

- Dashboard runs on **localhost:8080** by default (not exposed externally)
- Metrics files are mounted **read-only** in the container
- No sensitive data is collected (only system metrics)
- To expose externally, use reverse proxy (nginx, Caddy) with authentication

---

## 📝 Minimal Deployment (Docker Only)

If you only want the dashboard without cloning the repository:

**1. Create minimal files:**

**`docker-compose.yml`:**
```yaml
version: '3.8'

services:
  dashboard:
    image: <your-dockerhub-username>/system-monitor-dashboard:latest
    container_name: system-monitor-dashboard
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data:ro
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

**`monitor_windows.py`:**
Download from repository or create metrics collector.

**2. Run:**
```powershell
docker-compose up -d
while ($true) { python monitor_windows.py; Start-Sleep -Seconds 5 }
```

---

## ✅ Verification Steps

After deployment, verify everything works:

1. **Dashboard accessible:** http://localhost:8080
2. **Health check:** http://localhost:8080/health returns `{"status":"healthy"}`
3. **Metrics updating:** Refresh dashboard, values should change
4. **Container running:** `docker ps` shows container as "healthy"
5. **No errors:** `docker logs system-monitor-dashboard` shows no errors

---

## 🆘 Support

- 📖 Full documentation: [SOLUTION1_README.md](SOLUTION1_README.md)
- 🐛 Issues: Open GitHub issue
- 💬 Questions: Check documentation first

---

**Ready to deploy!** Follow the steps for your OS and you'll have a working system monitor in minutes. 🚀
