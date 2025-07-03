# Start VcXsrv for Crystal
# This script ensures VcXsrv is running with optimal settings for Electron apps

$vcxsrvPath = "C:\Program Files\VcXsrv\vcxsrv.exe"
$configPath = Join-Path $PSScriptRoot "config.xlaunch"

# Check if VcXsrv is installed
if (-not (Test-Path $vcxsrvPath)) {
    Write-Host "VcXsrv not found at $vcxsrvPath" -ForegroundColor Red
    Write-Host "Please install VcXsrv from https://github.com/marchaesen/vcxsrv/releases" -ForegroundColor Yellow
    exit 1
}

# Check if VcXsrv is already running
$vcxsrvProcess = Get-Process -Name "vcxsrv" -ErrorAction SilentlyContinue

if ($vcxsrvProcess) {
    Write-Host "VcXsrv is already running (PID: $($vcxsrvProcess.Id))" -ForegroundColor Green
    Write-Host "To restart, close VcXsrv from the system tray and run this script again" -ForegroundColor Yellow
} else {
    Write-Host "Starting VcXsrv..." -ForegroundColor Cyan
    
    # Start VcXsrv with the configuration file
    if (Test-Path $configPath) {
        Start-Process -FilePath $configPath
        Write-Host "VcXsrv started with Crystal configuration" -ForegroundColor Green
    } else {
        # Fallback to command line parameters if config file not found
        $params = "-multiwindow", "-clipboard", "-nowgl", "-ac", "-dpi", "auto"
        Start-Process -FilePath $vcxsrvPath -ArgumentList $params
        Write-Host "VcXsrv started with default parameters" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "You can now run Crystal from WSL with:" -ForegroundColor Cyan
    Write-Host "  cd ~/proj/crystal" -ForegroundColor White
    Write-Host "  pnpm run dev" -ForegroundColor White
}

# Display WSL configuration reminder
Write-Host ""
Write-Host "Make sure your WSL ~/.bashrc includes:" -ForegroundColor Yellow
Write-Host '  export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk ''{print $2; exit;}''):0.0' -ForegroundColor Gray
Write-Host ""