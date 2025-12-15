# Installation Guide

Complete installation instructions for System Monitor on Windows, Linux, and macOS.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Methods](#installation-methods)
3. [Platform-Specific Instructions](#platform-specific-instructions)
4. [Docker Installation](#docker-installation)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### All Platforms

- **Bash**: Version 4.0 or higher
- **Python**: Version 3.7 or higher
- **Git**: For cloning the repository (optional)
- **Docker**: For containerized deployment (optional)

### Platform-Specific Tools

#### Linux
- `lm-sensors` - CPU temperature monitoring
- `smartmontools` - Disk SMART status
- `dialog` or `whiptail` - CLI dashboard
- `bc` - Mathematical calculations
- `sysstat` - System statistics

#### macOS
- Xcode Command Line Tools
- Homebrew package manager
- `smartmontools` via Homebrew

#### Windows
- Git Bash or Windows Subsystem for Linux (WSL)
- Python 3 from python.org or Microsoft Store

## Installation Methods

### Method 1: Automated Installation (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd system-monitor

# Make installation script executable
chmod +x install.sh

# Run installer
./install.sh
```

The installer will:
1. Detect your platform
2. Install required dependencies
3. Set up directories
4. Configure scripts
5. Optionally set up cron jobs

### Method 2: Manual Installation

#### Step 1: Download/Clone Project

```bash
cd /path/to/your/projects
git clone <repository-url>
cd system-monitor
```

#### Step 2: Install Dependencies

**Linux (Debian/Ubuntu)**:
```bash
sudo apt-get update
sudo apt-get install -y bash coreutils python3 python3-pip bc sysstat \
    net-tools lm-sensors smartmontools dialog curl

pip3 install flask jinja2 markdown plotly pandas
```

**Linux (RHEL/CentOS)**:
```bash
sudo yum install -y bash coreutils python3 python3-pip bc sysstat \
    net-tools lm_sensors smartmontools dialog curl

pip3 install flask jinja2 markdown plotly pandas
```

**macOS**:
```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install bash coreutils python3 dialog smartmontools

pip3 install flask jinja2 markdown plotly pandas
```

**Windows**:
```bash
# Install Python packages (in Git Bash or WSL)
pip3 install flask jinja2 markdown plotly pandas
```

#### Step 3: Set Up Directories

```bash
mkdir -p data/metrics data/reports data/logs data/alerts
```

#### Step 4: Make Scripts Executable

```bash
chmod +x scripts/*.sh
chmod +x scripts/collectors/*.sh
chmod +x install.sh
```

#### Step 5: Configure Environment

```bash
cp .env.example .env
# Edit .env with your preferences
nano .env
```

## Platform-Specific Instructions

### Linux

1. **Install sensors** (for CPU temperature):
```bash
sudo apt-get install lm-sensors
sudo sensors-detect --auto
```

2. **Set up SMART monitoring** (optional, requires sudo):
```bash
sudo smartctl --scan
```

3. **Test the monitor**:
```bash
bash scripts/monitor.sh --test
```

### macOS

1. **Install additional tools**:
```bash
brew install osx-cpu-temp  # For CPU temperature
```

2. **Grant permissions**:
- System Preferences → Security & Privacy → Privacy
- Allow Terminal/iTerm to access system information

3. **Test the monitor**:
```bash
bash scripts/monitor.sh --test
```

### Windows

#### Using Git Bash

1. **Install Git for Windows**: Download from https://git-scm.com/

2. **Install Python**: Download from https://www.python.org/

3. **Run in Git Bash**:
```bash
cd /c/path/to/system-monitor
bash scripts/monitor.sh --test
```

#### Using WSL (Recommended)

1. **Enable WSL**:
```powershell
wsl --install
```

2. **Install Ubuntu** from Microsoft Store

3. **Follow Linux instructions** inside WSL

## Docker Installation

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+

### Installation

1. **Install Docker**:

**Linux**:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**macOS**:
- Download Docker Desktop from https://www.docker.com/products/docker-desktop

**Windows**:
- Download Docker Desktop from https://www.docker.com/products/docker-desktop

2. **Configure environment**:
```bash
cp .env.example .env
# Edit .env as needed
```

3. **Build and start containers**:
```bash
# Basic setup
docker-compose up -d

# With InfluxDB
docker-compose --profile with-influxdb up -d
```

4. **Verify containers are running**:
```bash
docker-compose ps
```

## Verification

### Test Monitoring Script

```bash
bash scripts/monitor.sh --test
```

Expected output: JSON with system metrics

### Test CLI Dashboard

```bash
bash scripts/dashboard_cli.sh
```

Expected: Interactive menu appears

### Test Web Dashboard

1. **Start reporter**:
```bash
# Native
python3 reporting/reporter.py

# Docker
docker-compose up -d
```

2. **Access in browser**:
```
http://localhost:8080
```

### Verify Data Collection

```bash
# Run monitor once
bash scripts/monitor.sh --test

# Check data files
ls -la data/metrics/
cat data/metrics/latest.json
```

## Troubleshooting

### Issue: "Command not found: sensors"

**Solution (Linux)**:
```bash
sudo apt-get install lm-sensors
sudo sensors-detect --auto
```

### Issue: "Permission denied" for SMART status

**Solution**:
```bash
# Run specific commands with sudo
sudo smartctl -H /dev/sda

# Or add user to sudoers for smartctl (advanced)
```

### Issue: Python dependencies not found

**Solution**:
```bash
# Install in user directory
pip3 install --user flask jinja2 markdown plotly pandas

# Or use virtual environment
python3 -m venv venv
source venv/bin/activate
pip install flask jinja2 markdown plotly pandas
```

### Issue: Dialog/Whiptail not found

**Solution (Linux)**:
```bash
sudo apt-get install dialog
# or
sudo apt-get install whiptail
```

**Solution (macOS)**:
```bash
brew install dialog
```

### Issue: Docker containers won't start

**Solution**:
```bash
# Check logs
docker-compose logs

# Rebuild
docker-compose down
docker-compose up --build

# Check permissions
sudo chown -R $USER:$USER data/
```

### Issue: Web dashboard shows "No data available"

**Solution**:
```bash
# Ensure monitor has run at least once
bash scripts/monitor.sh --test

# Check data directory
ls -la data/metrics/

# Restart reporter
docker-compose restart reporter
```

## Post-Installation

### Set Up Automatic Monitoring

**Using cron (Linux/macOS)**:
```bash
# Edit crontab
crontab -e

# Add line to run every 5 minutes
*/5 * * * * cd /path/to/system-monitor && bash scripts/monitor.sh >> data/logs/cron.log 2>&1
```

**Using Task Scheduler (Windows)**:
1. Open Task Scheduler
2. Create Basic Task
3. Set trigger: "Daily" or "At startup"
4. Set action: Run `bash scripts/monitor.sh`

### Configure Alerts

Edit `config/alert_thresholds.conf`:
```bash
CPU_USAGE_WARNING=70
CPU_USAGE_CRITICAL=90
MEMORY_USAGE_WARNING=80
MEMORY_USAGE_CRITICAL=95
```

### Enable Email Notifications

Edit `.env`:
```bash
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
ALERT_EMAIL_TO=admin@example.com
```

## Uninstallation

```bash
# Stop Docker containers
docker-compose down

# Remove cron job
crontab -e  # Delete the monitoring line

# Remove files
cd ..
rm -rf system-monitor
```

## Next Steps

- Read the [User Guide](USER_GUIDE.md) to learn how to use the system
- Check the [README](../README.md) for feature overview
- Review [PRESENTATION.md](PRESENTATION.md) for demo scenarios
