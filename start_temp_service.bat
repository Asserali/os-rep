@echo off
echo ================================================
echo  CPU Temperature Service for Docker
echo ================================================
echo.
echo Starting LibreHardwareMonitor...
start "" /MIN "%~dp0LibreHardwareMonitor\LibreHardwareMonitor.exe"

timeout /t 3 /nobreak >nul

echo Starting Temperature HTTP Service on port 5555...
echo.
echo Container can now access: http://host.docker.internal:5555/cpu/temperature
echo.

python temp_service.py

pause
