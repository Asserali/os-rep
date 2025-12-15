@echo off
echo ========================================
echo Starting System Monitor Dashboard
echo ========================================
echo.

cd /d "%~dp0"

echo [1/2] Collecting current metrics...
python monitor_windows.py

echo.
echo [2/2] Starting Dashboard Server...
echo Dashboard will be available at: http://127.0.0.1:8080
echo.
python reporting/reporter.py
