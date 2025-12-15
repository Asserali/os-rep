# Run System Monitor GUI with Administrator Rights
# This PowerShell script requests admin privileges to enable CPU temperature monitoring

Write-Host "========================================" -ForegroundColor Green
Write-Host "System Monitor GUI - Admin Mode" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "Running with Administrator privileges ✓" -ForegroundColor Green
    Write-Host "CPU temperature monitoring enabled." -ForegroundColor Green
    Write-Host ""
    Write-Host "Starting GUI..." -ForegroundColor Yellow
    Write-Host ""
    
    # Run the GUI
    python monitor_gui.py
} else {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Write-Host "Please approve the UAC prompt." -ForegroundColor Yellow
    Write-Host ""
    
    # Restart this script with admin rights
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
}
