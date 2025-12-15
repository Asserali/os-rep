# Quick Start - Pull & Run

## For users pulling from Docker Hub

### Windows

**1. Create project folder:**
```powershell
mkdir system-monitor
cd system-monitor
mkdir data\metrics
```

**2. Download monitor script:**
```powershell
# Download monitor_windows.py from repository
# Or create it manually (see repository)
```

**3. Install Python dependencies:**
```powershell
pip install psutil wmi
```

**4. Pull and run dashboard:**
```powershell
docker pull <dockerhub-username>/system-monitor-dashboard:latest

docker run -d --name system-monitor-dashboard `
  -p 8080:8080 `
  -v ${PWD}/data:/data:ro `
  --restart unless-stopped `
  <dockerhub-username>/system-monitor-dashboard:latest
```

**5. Start metrics collection:**
```powershell
# Run in background
start /min powershell -Command "while (`$true) { python monitor_windows.py; Start-Sleep -Seconds 5 }"
```

**6. Open dashboard:**
```
http://localhost:8080
```

---

### Linux

**1. Create project folder:**
```bash
mkdir -p system-monitor/data/metrics
cd system-monitor
```

**2. Download monitor script:**
```bash
# Download monitor_linux.py from repository
# Example (replace with actual URL):
# wget https://raw.githubusercontent.com/<repo>/main/monitor_linux.py
# Or copy the file manually
```

**3. Install dependencies:**
```bash
pip3 install psutil
```

**4. Pull and run dashboard:**
```bash
docker pull <dockerhub-username>/system-monitor-dashboard:latest

docker run -d --name system-monitor-dashboard \
  -p 8080:8080 \
  -v $(pwd)/data:/data:ro \
  --restart unless-stopped \
  <dockerhub-username>/system-monitor-dashboard:latest
```

**5. Start metrics collection:**
```bash
# Quick start
chmod +x run_solution1.sh
./run_solution1.sh

# Or manually in background:
nohup bash -c "while true; do python3 monitor_linux.py >/dev/null 2>&1; sleep 5; done" &
```

**6. Open dashboard:**
```
http://localhost:8080
```

---

## Required Files

You only need **2 files**:

1. **Dashboard container** (pull from Docker Hub) ✅
2. **Metrics collector** (`monitor_windows.py` or `monitor_linux.py`) - download from repo

That's it! The dashboard is portable, the agent is platform-specific.
