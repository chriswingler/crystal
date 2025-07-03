#!/bin/bash
# Electron wrapper script to ensure proper environment for VcXsrv

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CRYSTAL_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "Crystal Electron Wrapper for VcXsrv"
echo "==================================="
echo ""

# Set display environment
export DISPLAY=localhost:0.0
export LIBGL_ALWAYS_INDIRECT=1
export ELECTRON_ENABLE_LOGGING=1

# Disable WSLg
unset WAYLAND_DISPLAY

echo "Environment Configuration:"
echo "  DISPLAY=$DISPLAY"
echo "  LIBGL_ALWAYS_INDIRECT=$LIBGL_ALWAYS_INDIRECT"
echo "  ELECTRON_ENABLE_LOGGING=$ELECTRON_ENABLE_LOGGING"
echo "  WAYLAND_DISPLAY=$WAYLAND_DISPLAY (unset)"
echo ""

# Test X11 connection
echo "Testing X11 connection..."
if timeout 2 xset q &>/dev/null; then
    echo "✓ X11 connection successful"
else
    echo "✗ X11 connection failed"
    echo ""
    echo "Please ensure:"
    echo "1. VcXsrv is running on Windows"
    echo "2. Try running: powershell.exe -Command \"Start-Process 'C:\\Program Files\\VcXsrv\\vcxsrv.exe' -ArgumentList '-multiwindow','-clipboard','-ac','-nowgl'\""
    exit 1
fi
echo ""

# Navigate to Crystal directory
cd "$CRYSTAL_DIR"

# Check if frontend is already running
if lsof -i:4521 &>/dev/null; then
    echo "Frontend already running on port 4521"
    FRONTEND_PID=""
else
    echo "Starting frontend..."
    pnpm run --filter frontend dev &
    FRONTEND_PID=$!
    
    # Wait for frontend to be ready
    echo "Waiting for frontend to start..."
    while ! curl -s http://localhost:4521 >/dev/null; do
        sleep 1
        echo -n "."
    done
    echo " Ready!"
fi
echo ""

# Run Electron directly with full path and environment
echo "Starting Electron..."
echo "Command: $CRYSTAL_DIR/node_modules/.bin/electron $CRYSTAL_DIR"
echo ""

# Export all environment variables for child process
export DISPLAY
export LIBGL_ALWAYS_INDIRECT
export ELECTRON_ENABLE_LOGGING

# Run Electron
"$CRYSTAL_DIR/node_modules/.bin/electron" "$CRYSTAL_DIR"

# Cleanup
if [ -n "$FRONTEND_PID" ]; then
    echo ""
    echo "Stopping frontend..."
    kill $FRONTEND_PID 2>/dev/null || true
fi