@echo off
REM ============================================================================
REM Solution 1 - Continuous Monitor + Dashboard
REM Runs metrics collection in background + Dashboard in Docker
REM ============================================================================

echo.
echo ================================================================
echo  Solution 1: Host Agent + Container Dashboard
echo ================================================================
echo.

echo [1/2] Starting dashboard container...
docker-compose -f docker-compose-solution1.yml up -d
if %errorLevel% neq 0 (
    echo [ERROR] Failed to start dashboard container
    echo Make sure Docker Desktop is running!
    pause
    exit /b 1
)

echo.
echo [2/2] Starting continuous metrics collection...
echo Running in background (PowerShell window will minimize)
echo.

REM Start metrics collection in a minimized PowerShell window
start /min powershell -WindowStyle Minimized -Command "& { cd '%~dp0' ; while ($true) { python monitor_windows.py > $null ; Start-Sleep -Seconds 5 } }"

echo.
echo ================================================================
echo  SUCCESS! Solution 1 is running
echo ================================================================
echo.
echo  Metrics Collection: Running in background (every 5 seconds)
echo  Dashboard URL:      http://localhost:8080
echo.
echo  Management Commands:
echo  --------------------
echo  View logs:       docker logs -f system-monitor-dashboard
echo  Stop dashboard:  docker-compose -f docker-compose-solution1.yml down
echo  Stop metrics:    Close the minimized PowerShell window
echo.
echo  Opening dashboard in browser...
timeout /t 2 >nul
start http://localhost:8080
echo.
pause
