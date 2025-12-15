@echo off
echo ========================================
echo Starting Docker Monitor with CPU Temps
echo ========================================
echo.

cd /d "%~dp0"

echo [1/2] Starting Temperature Service...
start /B python temp_service.py

echo [2/2] Waiting for service to initialize...
timeout /t 3 /nobreak >nul

echo [3/3] Starting Docker Monitor...
docker-compose -f docker-compose-bash.yml up

echo.
echo Docker monitor stopped.
pause
