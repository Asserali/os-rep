# System Monitor - Windows Agent Installation Script
# This installs the Windows monitoring agent as a Windows Service

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "System Monitor - Windows Agent Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "[1/5] Checking Python installation..." -ForegroundColor Green

# Check if Python is installed
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "ERROR: Python is not installed or not in PATH!" -ForegroundColor Red
    Write-Host "Please install Python 3.9+ from python.org" -ForegroundColor Yellow
    pause
    exit 1
}

$pythonVersion = python --version
Write-Host "  Found: $pythonVersion" -ForegroundColor Gray

Write-Host "[2/5] Installing Python dependencies..." -ForegroundColor Green

# Install required packages
python -m pip install --quiet --upgrade pip
python -m pip install --quiet pywin32 psutil wmi plotly

Write-Host "  Dependencies installed successfully" -ForegroundColor Gray

Write-Host "[3/5] Installing Windows Service..." -ForegroundColor Green

# Install the service
try {
    python windows_service.py install
    Write-Host "  Service 'SystemMonitor' installed" -ForegroundColor Gray
} catch {
    Write-Host "  WARNING: Service may already be installed" -ForegroundColor Yellow
}

Write-Host "[4/5] Starting the service..." -ForegroundColor Green

# Start the service
try {
    python windows_service.py start
    Write-Host "  Service started successfully" -ForegroundColor Gray
} catch {
    Write-Host "  ERROR: Failed to start service" -ForegroundColor Red
    Write-Host "  You can start it manually from Services (services.msc)" -ForegroundColor Yellow
}

Write-Host "[5/5] Verifying installation..." -ForegroundColor Green

# Wait a moment for the service to create the first metrics file
Start-Sleep -Seconds 10

$metricsFile = "data\metrics\latest_windows.json"
if (Test-Path $metricsFile) {
    Write-Host "  Metrics file created: $metricsFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "SUCCESS: Windows Agent installed and running!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The agent is now running as a Windows Service and will:" -ForegroundColor Cyan
    Write-Host "  - Start automatically with Windows" -ForegroundColor Gray
    Write-Host "  - Collect metrics every 5 seconds" -ForegroundColor Gray
    Write-Host "  - Write to: $metricsFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Run dashboard: docker-compose -f docker-compose-solution1.yml up -d" -ForegroundColor Gray
    Write-Host "  2. Open browser: http://localhost:8080" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To manage the service:" -ForegroundColor Yellow
    Write-Host "  - View status: python windows_service.py status" -ForegroundColor Gray
    Write-Host "  - Stop: python windows_service.py stop" -ForegroundColor Gray
    Write-Host "  - Start: python windows_service.py start" -ForegroundColor Gray
    Write-Host "  - Uninstall: python windows_service.py remove" -ForegroundColor Gray
} else {
    Write-Host "  WARNING: Metrics file not created yet" -ForegroundColor Yellow
    Write-Host "  The service may take a few moments to start collecting metrics" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
pause
