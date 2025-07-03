#!/bin/bash
# Start VcXsrv with TCP listening enabled

echo "Starting VcXsrv with TCP listening..."

# Kill any existing VcXsrv
taskkill.exe /F /IM vcxsrv.exe 2>/dev/null || true
sleep 1

# Start VcXsrv with explicit parameters
echo "Launching VcXsrv..."
"/mnt/c/Program Files/VcXsrv/vcxsrv.exe" \
    -multiwindow \
    -clipboard \
    -ac \
    -listen tcp \
    -from "*" \
    -nowgl \
    -silent-dup-error &

VCXSRV_PID=$!
sleep 3

# Check if it's running
if tasklist.exe | grep -qi vcxsrv; then
    echo "✓ VcXsrv started"
    
    # Test connectivity
    echo "Testing connectivity..."
    for port in 6000 6001; do
        echo -n "  Port $port: "
        nc -zv localhost $port 2>&1 | grep -q succeeded && echo "✓ OPEN" || echo "✗ CLOSED"
    done
else
    echo "✗ VcXsrv failed to start"
fi

echo ""
echo "Now test with:"
echo "  export DISPLAY=localhost:0.0"
echo "  xeyes"