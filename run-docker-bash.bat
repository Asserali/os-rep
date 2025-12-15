@echo off
REM Build and run the bash monitor in Docker on Windows

echo ================================================
echo   Building Docker Container for Bash Monitor
echo ================================================
echo.

REM Build the Docker image
docker-compose -f docker-compose-bash.yml build

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================================
    echo   Starting Bash Monitor Container
    echo ================================================
    echo.
    
    REM Run the container
    docker-compose -f docker-compose-bash.yml up
) else (
    echo.
    echo Build failed! Please check the error messages above.
    exit /b 1
)
