#!/bin/bash
# Fix VcXsrv for WSL2

echo "=== VcXsrv WSL2 Fix ==="
echo ""

# Get the Windows host IP from WSL's perspective
WINDOWS_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}')
echo "Windows host IP (from WSL): $WINDOWS_HOST"

# Get WSL's IP from Windows perspective
WSL_IP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
echo "WSL IP: $WSL_IP"
echo ""

echo "To make VcXsrv work with WSL2:"
echo ""
echo "1. On Windows, run this PowerShell command as Administrator:"
echo "   New-NetFirewallRule -DisplayName 'WSL2 X Server' -Direction Inbound -LocalPort 6000 -Protocol TCP -Action Allow"
echo ""
echo "2. Start VcXsrv with these EXACT settings:"
echo "   - Multiple windows"
echo "   - Start no client" 
echo "   - UNCHECK 'Native opengl'"
echo "   - CHECK 'Disable access control'"
echo "   - Add to 'Additional parameters': -listen tcp"
echo ""
echo "3. In WSL, use:"
echo "   export DISPLAY=$WINDOWS_HOST:0.0"
echo ""

# Test current connectivity
echo "Testing connectivity to Windows host..."
echo -n "Port 6000 on $WINDOWS_HOST: "
timeout 2 nc -zv $WINDOWS_HOST 6000 2>&1 | grep -q succeeded && echo "✓ OPEN" || echo "✗ CLOSED (VcXsrv not accessible)"

# Alternative: Use socat to forward
echo ""
echo "Alternative: Create a local forwarder (if needed):"
echo "sudo apt install socat"
echo "socat TCP-LISTEN:6000,fork,bind=127.0.0.1 TCP:$WINDOWS_HOST:6000 &"