@echo off
REM Windows Batch Script to Run System Monitor
echo ========================================
echo System Monitor - Windows Edition
echo ========================================
echo.

REM Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python not found. Please install Python 3.7+
    pause
    exit /b 1
)

echo [1/3] Checking Python packages...
pip show psutil >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing psutil...
    pip install psutil --quiet
)

echo [2/3] Collecting system metrics...
python monitor_windows.py
if %errorlevel% neq 0 (
    echo Error running monitoring script
    pause
    exit /b 1
)

echo.
echo [3/3] Metrics collected successfully!
echo.
echo Data saved to: data\metrics\latest.json
echo.
echo ========================================
echo Next Steps:
echo ========================================
echo 1. View CLI: python monitor_windows.py
echo 2. Install Flask for web dashboard:
echo    pip install flask plotly
echo 3. Run web dashboard:
echo    python reporting/reporter.py
echo    Then open: http://localhost:8080
echo ========================================
echo.
pause
