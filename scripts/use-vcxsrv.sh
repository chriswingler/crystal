#!/bin/bash
# Switch from WSLg to VcXsrv

echo "Switching to VcXsrv..."

# Disable WSLg
export WSL_DISABLE_GUI=1
unset DISPLAY
unset WAYLAND_DISPLAY

# Kill any existing VcXsrv and restart with simple config
taskkill.exe /F /IM vcxsrv.exe 2>/dev/null || true
sleep 1

# Start VcXsrv with the simplest possible config
echo "Starting VcXsrv..."
powershell.exe -Command "Start-Process 'C:\Program Files\VcXsrv\vcxsrv.exe' -ArgumentList ':0 -multiwindow -clipboard -ac'"

sleep 3

# Get Windows host IP
WINDOWS_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}')

# Try different display options
echo "Testing display options..."
for display in "localhost:0" ":0" "$WINDOWS_HOST:0" "127.0.0.1:0" "host.docker.internal:0"; do
    echo -n "Testing DISPLAY=$display ... "
    if DISPLAY=$display timeout 1 xset q &>/dev/null; then
        echo "✓ WORKS!"
        export DISPLAY=$display
        break
    else
        echo "✗ Failed"
    fi
done

if [ -n "$DISPLAY" ]; then
    echo ""
    echo "Success! Using DISPLAY=$DISPLAY"
    echo ""
    echo "Now run Crystal with:"
    echo "  cd ~/proj/crystal"
    echo "  DISPLAY=$DISPLAY pnpm run dev"
else
    echo ""
    echo "No working display found. VcXsrv may need additional configuration."
fi