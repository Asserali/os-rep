@echo off
echo ============================================
echo  System Monitor with CPU Temperature
echo ============================================
echo.
cd /d "%~dp0"

REM Check if already running as admin
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrator privileges.
    echo.
    
    REM Check if LibreHardwareMonitor is already running
    tasklist /FI "IMAGENAME eq LibreHardwareMonitor.exe" 2>NUL | find /I /N "LibreHardwareMonitor.exe">NUL
    if "%ERRORLEVEL%"=="0" (
        echo LibreHardwareMonitor is already running.
    ) else (
        echo Starting LibreHardwareMonitor...
        start "" /MIN "%~dp0LibreHardwareMonitor\LibreHardwareMonitor.exe"
        timeout /t 3 /nobreak >nul
        echo LibreHardwareMonitor started successfully.
    )
    
    echo.
    echo Starting System Monitor GUI...
    python monitor_gui.py
    pause
) else (
    echo This script requires administrator privileges.
    echo Requesting elevation...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)
