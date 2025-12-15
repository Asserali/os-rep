@echo off
REM Continuous Windows metrics collection loop
cd /d "%~dp0"

:loop
python monitor_windows.py --silent
timeout /t 5 /nobreak >nul 2>&1
goto loop
