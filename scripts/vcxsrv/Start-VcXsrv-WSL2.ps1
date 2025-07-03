# PowerShell script to start VcXsrv properly for WSL2
# Run this from Windows (not WSL)

Write-Host "Starting VcXsrv for WSL2..." -ForegroundColor Cyan

# Kill existing VcXsrv
$vcxsrv = Get-Process vcxsrv -ErrorAction SilentlyContinue
if ($vcxsrv) {
    Write-Host "Stopping existing VcXsrv..." -ForegroundColor Yellow
    Stop-Process -Name vcxsrv -Force
    Start-Sleep -Seconds 1
}

# Get WSL2 IP range
$wslIP = bash.exe -c "ip addr show eth0 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1"
Write-Host "WSL2 IP: $wslIP" -ForegroundColor Green

# Check firewall rule
$firewallRule = Get-NetFirewallRule -DisplayName "VcXsrv WSL2" -ErrorAction SilentlyContinue
if (-not $firewallRule) {
    Write-Host "Creating firewall rule..." -ForegroundColor Yellow
    if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544') {
        New-NetFirewallRule -DisplayName "VcXsrv WSL2" -Direction Inbound -Program "C:\Program Files\VcXsrv\vcxsrv.exe" -Action Allow -Profile Any
        New-NetFirewallRule -DisplayName "X Server Port" -Direction Inbound -LocalPort 6000-6010 -Protocol TCP -Action Allow
    } else {
        Write-Host "Please run as Administrator to create firewall rules" -ForegroundColor Red
    }
}

# Start VcXsrv with proper parameters
$vcxsrvPath = "C:\Program Files\VcXsrv\vcxsrv.exe"
$arguments = @(
    ":0",
    "-multiwindow",
    "-clipboard",
    "-primary",
    "-nowgl",
    "-ac",
    "-listen", "tcp"
)

Write-Host "Starting VcXsrv with arguments: $($arguments -join ' ')" -ForegroundColor Cyan
Start-Process -FilePath $vcxsrvPath -ArgumentList $arguments

Start-Sleep -Seconds 2

# Verify it's running
if (Get-Process vcxsrv -ErrorAction SilentlyContinue) {
    Write-Host "`nVcXsrv started successfully!" -ForegroundColor Green
    Write-Host "`nIn WSL, use:" -ForegroundColor Yellow
    Write-Host "  export DISPLAY=$(hostname).local:0.0" -ForegroundColor White
    Write-Host "     or" -ForegroundColor Gray
    Write-Host "  export DISPLAY=10.255.255.254:0.0" -ForegroundColor White
} else {
    Write-Host "Failed to start VcXsrv" -ForegroundColor Red
}