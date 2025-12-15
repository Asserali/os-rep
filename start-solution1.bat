@echo off
REM Quick start script for Solution 1
echo ========================================
echo System Monitor - Solution 1 Quick Start
echo ========================================
echo.

echo Step 1: Installing Windows Agent...
echo.
powershell -ExecutionPolicy Bypass -File install-windows-agent.ps1

echo.
echo Step 2: Starting Dashboard Container...
echo.
docker-compose -f docker-compose-solution1.yml up -d

echo.
echo Step 3: Waiting for dashboard to start...
timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo System Monitor is now running!
echo ========================================
echo.
echo Dashboard: http://localhost:8080
echo.
echo Opening dashboard in browser...
start http://localhost:8080

echo.
echo Press any key to exit...
pause >nul
