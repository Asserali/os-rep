# Running System Monitor in Docker

## Quick Start

### Windows:
```cmd
run-docker-bash.bat
```

### Linux/WSL:
```bash
bash run-docker-bash.sh
```

## Manual Docker Commands

### Build the container:
```bash
docker-compose -f docker-compose-bash.yml build
```

### Run the container:
```bash
docker-compose -f docker-compose-bash.yml up
```

### Run in detached mode (background):
```bash
docker-compose -f docker-compose-bash.yml up -d
```

### View logs:
```bash
docker logs -f system-monitor-bash
```

### Stop the container:
```bash
docker-compose -f docker-compose-bash.yml down
```

## What's Included

The Docker container runs Ubuntu 22.04 with:
- ✅ Bash monitoring script (`monitor_wsl.sh`)
- ✅ CPU temperature reading via LibreHardwareMonitor (if running on host)
- ✅ GPU monitoring (NVIDIA drivers included)
- ✅ Full system access (`privileged` mode)
- ✅ Host `/proc` and `/sys` mounted for accurate metrics

## Requirements

- Docker Desktop installed and running
- For GPU monitoring: NVIDIA Container Toolkit (optional)
- LibreHardwareMonitor running on Windows host for CPU temps

## Notes

**CPU Temperature from Windows:**
The container can read CPU temperature from LibreHardwareMonitor running on your Windows host. Make sure:
1. LibreHardwareMonitor is running with admin rights on Windows
2. The container can access Windows Python via network or mounted volume

**GPU Monitoring:**
GPU metrics require nvidia-docker runtime. If you don't have NVIDIA GPU, the container will still run but skip GPU metrics.

## Troubleshooting

**Container won't start:**
- Make sure Docker Desktop is running
- Check if port 8080 is available

**No CPU temperature:**
- Start LibreHardwareMonitor on Windows first
- Make sure it's running as Administrator

**No GPU metrics:**
- Install NVIDIA Container Toolkit
- Or remove the GPU reservation from docker-compose-bash.yml
