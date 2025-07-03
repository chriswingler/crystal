#!/bin/bash
# Debug script to diagnose VcXsrv display issues

echo "=== VcXsrv Display Debugging ==="
echo ""

# Check current environment
echo "1. Current Environment Variables:"
echo "   DISPLAY=$DISPLAY"
echo "   WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
echo "   XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
echo ""

# Check possible DISPLAY values
echo "2. Testing Different DISPLAY Values:"
echo ""

# Test localhost:0.0
echo -n "   Testing DISPLAY=localhost:0.0 ... "
DISPLAY=localhost:0.0 timeout 2 xset q &>/dev/null && echo "✓ WORKS" || echo "✗ FAILED"

# Test :0
echo -n "   Testing DISPLAY=:0 ... "
DISPLAY=:0 timeout 2 xset q &>/dev/null && echo "✓ WORKS" || echo "✗ FAILED"

# Test with Windows host IP
WINDOWS_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}')
echo -n "   Testing DISPLAY=$WINDOWS_HOST:0.0 ... "
DISPLAY=$WINDOWS_HOST:0.0 timeout 2 xset q &>/dev/null && echo "✓ WORKS" || echo "✗ FAILED"

# Test 127.0.0.1:0.0
echo -n "   Testing DISPLAY=127.0.0.1:0.0 ... "
DISPLAY=127.0.0.1:0.0 timeout 2 xset q &>/dev/null && echo "✓ WORKS" || echo "✗ FAILED"

echo ""

# Check VcXsrv process
echo "3. VcXsrv Process Status:"
if tasklist.exe 2>/dev/null | grep -qi vcxsrv; then
    echo "   ✓ VcXsrv is running"
    echo "   Process details:"
    tasklist.exe | grep -i vcxsrv | sed 's/^/   /'
else
    echo "   ✗ VcXsrv is NOT running"
fi
echo ""

# Check network connectivity
echo "4. Network Connectivity Tests:"
echo -n "   Port 6000 on localhost: "
nc -zv localhost 6000 2>&1 | grep -q succeeded && echo "✓ OPEN" || echo "✗ CLOSED"

echo -n "   Port 6000 on $WINDOWS_HOST: "
nc -zv $WINDOWS_HOST 6000 2>&1 | grep -q succeeded && echo "✓ OPEN" || echo "✗ CLOSED"
echo ""

# Test with actual X11 app
echo "5. Testing with X11 Applications:"
for display in "localhost:0.0" ":0" "$WINDOWS_HOST:0.0"; do
    echo -n "   xeyes with DISPLAY=$display ... "
    DISPLAY=$display timeout 2 xeyes &>/dev/null &
    XEYES_PID=$!
    sleep 1
    if kill -0 $XEYES_PID 2>/dev/null; then
        echo "✓ WORKS"
        kill $XEYES_PID 2>/dev/null
    else
        echo "✗ FAILED"
    fi
done
echo ""

# Check electron
echo "6. Electron Environment Test:"
ELECTRON_PATH="$HOME/proj/crystal/node_modules/.bin/electron"
if [ -f "$ELECTRON_PATH" ]; then
    echo "   Electron found at: $ELECTRON_PATH"
    echo "   Testing electron with different DISPLAY values:"
    
    for display in "localhost:0.0" ":0"; do
        echo -n "   DISPLAY=$display electron --version ... "
        DISPLAY=$display timeout 2 $ELECTRON_PATH --version 2>&1 | grep -q "Electron" && echo "✓ WORKS" || echo "✗ FAILED"
    done
else
    echo "   ✗ Electron not found"
fi
echo ""

# Recommendations
echo "7. Recommendations:"
echo ""
WORKING_DISPLAY=""
for display in "localhost:0.0" ":0" "$WINDOWS_HOST:0.0"; do
    if DISPLAY=$display timeout 1 xset q &>/dev/null; then
        WORKING_DISPLAY=$display
        break
    fi
done

if [ -n "$WORKING_DISPLAY" ]; then
    echo "   ✓ Use DISPLAY=$WORKING_DISPLAY"
    echo ""
    echo "   Add to your ~/.bashrc:"
    echo "   export DISPLAY=$WORKING_DISPLAY"
    echo "   export LIBGL_ALWAYS_INDIRECT=1"
else
    echo "   ✗ No working DISPLAY found. Please check:"
    echo "   1. VcXsrv is running on Windows"
    echo "   2. Windows Firewall allows VcXsrv"
    echo "   3. VcXsrv was started with -ac flag"
fi