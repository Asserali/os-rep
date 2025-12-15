@echo off
REM Run System Monitor GUI with Administrator Rights
REM This enables CPU temperature monitoring without LibreHardwareMonitor

echo ========================================
echo System Monitor GUI - Admin Mode
echo ========================================
echo.
echo Running with administrator privileges...
echo This may enable CPU temperature monitoring.
echo.

REM Check if already running as admin
net session >nul 2>&1
if %errorlevel% == 0 (
    echo Already running as Administrator.
    echo Starting GUI...
    python monitor_gui.py
) else (
    echo Requesting Administrator privileges...
    echo Please approve the UAC prompt.
    powershell -Command "Start-Process python -ArgumentList 'monitor_gui.py' -Verb RunAs -WorkingDirectory '%CD%'"
)
