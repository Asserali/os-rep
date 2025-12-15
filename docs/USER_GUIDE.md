# User Guide

Learn how to use the System Monitor effectively.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Running the Monitor](#running-the-monitor)
3. [Using the Web Dashboard](#using-the-web-dashboard)
4. [Using the CLI Dashboard](#using-the-cli-dashboard)
5. [Generating Reports](#generating-reports)
6. [Configuring Alerts](#configuring-alerts)
7. [API Usage](#api-usage)
8. [Best Practices](#best-practices)

## Getting Started

After installation, you have multiple ways to interact with the system:
- **CLI Dashboard**: Terminal-based interface
- **Web Dashboard**: Browser-based interface
- **Command Line**: Direct script execution
- **API**: Programmatic access

## Running the Monitor

### One-Time Collection

```bash
bash scripts/monitor.sh --test
```

This collects metrics once and displays them.

### Continuous Monitoring

```bash
bash scripts/monitor.sh
```

Runs continuously, collecting metrics every 60 seconds (configurable).

### Custom Interval

```bash
bash scripts/monitor.sh --interval 30
```

Collects metrics every 30 seconds.

## Using the Web Dashboard

### Starting the Dashboard

**With Docker**:
```bash
docker-compose up -d
```

**Without Docker**:
```bash
python3 reporting/reporter.py
```

### Accessing the Dashboard

Open your browser and navigate to:
```
http://localhost:8080
```

### Dashboard Features

1. **Real-time Metrics**:
   - CPU usage and temperature
   - Memory usage (RAM & Swap)
   - System load average
   - GPU utilization (if available)

2. **Disk Usage**:
   - All mounted filesystems
   - Usage percentages with color coding
   - Available space

3. **Network Statistics**:
   - Active connections
   - Interface traffic (RX/TX)
   - Packet counts and errors

4. **Historical Charts**:
   - CPU usage over time
   - Memory usage trends
   - Network traffic patterns

5. **Status Indicators**:
   - 🟢 Green: Normal (OK)
   - 🟡 Yellow: Warning
   - 🔴 Red: Critical

### Refreshing Data

- Click the **🔄 Refresh** button in the header
- Dashboard auto-refreshes every 60 seconds

## Using the CLI Dashboard

### Starting the CLI Dashboard

```bash
bash scripts/dashboard_cli.sh
```

### Navigation

Use arrow keys and Enter to navigate the menu:

1. **System Overview**: Quick summary of all metrics
2. **CPU Metrics**: Detailed CPU information
3. **Memory Metrics**: RAM and swap details
4. **Disk Usage**: All filesystem information
5. **Network Statistics**: Interface details
6. **GPU Information**: GPU metrics (if available)
7. **System Load**: Load averages and processes
8. **Generate Report**: Create Markdown or text reports
9. **Refresh Data**: Update metrics
0. **Exit**: Close the dashboard

### Reading Metrics

- **Progress Bars**: Visual representation of usage
- **Status**: OK, WARNING, or CRITICAL
- **Colors**: Green (OK), Yellow (Warning), Red (Critical)

## Generating Reports

### HTML Reports

**Via Web Interface**:
```
http://localhost:8080/report/html
```

**Via API**:
```bash
curl http://localhost:8080/report/html > report.html
```

### Markdown Reports

**Via Web Interface**:
```
http://localhost:8080/report/markdown
```

**Via CLI Dashboard**:
1. Select **Generate Report**
2. Choose **Markdown Report**

### Viewing Reports

Reports are saved in `data/reports/`:
```bash
ls -la data/reports/
cat data/reports/report_*.md
```

## Configuring Alerts

### Alert Thresholds

Edit `config/alert_thresholds.conf`:

```bash
# CPU Thresholds (percentage)
CPU_USAGE_WARNING=70
CPU_USAGE_CRITICAL=90
CPU_TEMP_WARNING=75
CPU_TEMP_CRITICAL=85

# Memory Thresholds (percentage)
MEMORY_USAGE_WARNING=80
MEMORY_USAGE_CRITICAL=95
```

### Alert Notifications

Alerts are sent to:
1. **Log Files**: `data/alerts/alerts.log`
2. **Desktop Notifications**: (if supported)
3. **Console**: When running interactively

### Viewing Alert History

```bash
cat data/alerts/alerts.log
```

Example alert:
```
[2025-12-11T14:30:00Z] [WARNING] CPU: CPU usage high (value: 75%)
[2025-12-11T14:35:00Z] [CRITICAL] Memory: Memory usage critical (value: 96%)
```

## API Usage

### Endpoints

#### Get Latest Metrics
```bash
curl http://localhost:8080/api/latest
```

Returns JSON with current metrics.

#### Get Historical Data
```bash
curl http://localhost:8080/api/historical/24
```

Returns metrics from last 24 hours.

#### Get Chart Data
```bash
curl http://localhost:8080/api/charts
```

Returns Plotly chart configurations.

### Using in Scripts

```bash
#!/bin/bash

# Get CPU usage
CPU_USAGE=$(curl -s http://localhost:8080/api/latest | \
    python3 -c "import sys, json; print(json.load(sys.stdin)['cpu']['usage_percent'])")

echo "Current CPU usage: ${CPU_USAGE}%"

# Check if critical
if (( $(echo "$CPU_USAGE > 90" | bc -l) )); then
    echo "WARNING: High CPU usage!"
fi
```

## Best Practices

### Data Management

1. **Regular Cleanup**:
```bash
# Automatic cleanup (configured in monitor.conf)
RETENTION_DAYS=7

# Manual cleanup
find data/metrics -type f -mtime +7 -delete
```

2. **Backup Important Reports**:
```bash
cp data/reports/report_*.md ~/backups/
```

### Performance Optimization

1. **Adjust Monitoring Interval**:
   - Shorter intervals (5-10s): High-frequency monitoring
   - Longer intervals (60-300s): Reduced overhead

2. **Disable Unused Monitors**:
Edit `config/monitor.conf`:
```bash
ENABLE_GPU_MONITOR=false  # If no GPU
```

### Security

1. **Protect Sensitive Data**:
```bash
chmod 700 data/
chmod 600 .env
```

2. **Use Environment Variables**:
```bash
# Don't commit .env to version control
echo ".env" >> .gitignore
```

3. **Limit API Access**:
Configure firewall rules for port 8080.

### Monitoring Best Practices

1. **Establish Baselines**:
   - Run for 24-48 hours to understand normal patterns
   - Adjust thresholds based on baseline

2. **Regular Reviews**:
   - Check alerts weekly
   - Review trends monthly
   - Update thresholds as needed

3. **Document Changes**:
   - Keep notes on configuration changes
   - Track when thresholds were adjusted

## Troubleshooting

### No Data Appearing

**Check if monitor is running**:
```bash
ps aux | grep monitor.sh
```

**Check data files**:
```bash
ls -la data/metrics/
cat data/metrics/latest.json
```

**Run test**:
```bash
bash scripts/monitor.sh --test
```

### Charts Not Loading

**Check browser console** for errors.

**Verify API is accessible**:
```bash
curl http://localhost:8080/api/charts
```

### High Resource Usage

**Reduce monitoring frequency**:
Edit `config/monitor.conf`:
```bash
MONITOR_INTERVAL=300  # 5 minutes instead of 1
```

**Disable unused features**:
```bash
ENABLE_GPU_MONITOR=false
ENABLE_NETWORK_MONITOR=false
```

### Alerts Not Working

**Check configuration**:
```bash
cat config/alert_thresholds.conf
```

**Verify alert log**:
```bash
tail -f data/alerts/alerts.log
```

**Test manually**:
```bash
bash scripts/monitor.sh --test | bash scripts/alert_manager.sh
```

## Advanced Usage

### Custom Metrics

Add custom collectors in `scripts/collectors/`:

```bash
#!/bin/bash
# custom_monitor.sh

source "$(dirname "$0")/../utils.sh"

collect_custom_metrics() {
    cat <<EOF
{
  "custom_value": 42,
  "timestamp": "$(get_iso_timestamp)"
}
EOF
}

collect_custom_metrics
```

### Integration with Other Tools

**Export to CSV**:
```bash
python3 << EOF
import json, csv

with open('data/metrics/latest.json') as f:
    data = json.load(f)

with open('metrics.csv', 'w') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['CPU', 'Memory', 'Disk'])
    writer.writerow([
        data['cpu']['usage_percent'],
        data['memory']['usage_percent'],
        data['disk']['filesystems'][0]['usage_percent']
    ])
EOF
```

**Send to External Service**:
```bash
curl -X POST https://example.com/metrics \
  -H "Content-Type: application/json" \
  -d @data/metrics/latest.json
```

## Next Steps

- Customize alert thresholds for your environment
- Set up automated reporting schedules
- Integrate with your existing monitoring infrastructure
- Explore the API for custom integrations
