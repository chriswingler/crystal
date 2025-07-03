#!/bin/bash
# Direct Crystal execution script - bypasses npm/pnpm environment issues

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CRYSTAL_DIR="$(dirname "$SCRIPT_DIR")"

echo "Crystal Direct Launcher (VcXsrv)"
echo "================================"
echo ""

# Function to test display
test_display() {
    local display=$1
    echo -n "Testing DISPLAY=$display ... "
    DISPLAY=$display timeout 1 xset q &>/dev/null && echo "✓ WORKS" || echo "✗ FAILED"
}

# Find working display
echo "Finding working display..."
WORKING_DISPLAY=""
for display in "localhost:0.0" ":0" "127.0.0.1:0.0"; do
    if DISPLAY=$display timeout 1 xset q &>/dev/null; then
        WORKING_DISPLAY=$display
        echo "✓ Found working display: $WORKING_DISPLAY"
        break
    fi
done

if [ -z "$WORKING_DISPLAY" ]; then
    echo "✗ No working display found!"
    echo ""
    echo "Trying to start VcXsrv..."
    powershell.exe -Command "Start-Process -FilePath 'C:\Program Files\VcXsrv\vcxsrv.exe' -ArgumentList '-multiwindow','-clipboard','-ac','-nowgl','-silent-dup-error'" 2>/dev/null || true
    sleep 3
    
    # Try again
    for display in "localhost:0.0" ":0" "127.0.0.1:0.0"; do
        if DISPLAY=$display timeout 1 xset q &>/dev/null; then
            WORKING_DISPLAY=$display
            echo "✓ Found working display after starting VcXsrv: $WORKING_DISPLAY"
            break
        fi
    done
fi

if [ -z "$WORKING_DISPLAY" ]; then
    echo "✗ Still no working display. Please start VcXsrv manually."
    exit 1
fi

# Set environment
export DISPLAY=$WORKING_DISPLAY
export LIBGL_ALWAYS_INDIRECT=1
export ELECTRON_ENABLE_LOGGING=1
export NODE_ENV=development

# Disable WSLg
unset WAYLAND_DISPLAY
unset XDG_RUNTIME_DIR

echo ""
echo "Environment:"
echo "  DISPLAY=$DISPLAY"
echo "  Working directory: $CRYSTAL_DIR"
echo ""

cd "$CRYSTAL_DIR"

# Build if necessary
if [ ! -d "main/dist" ]; then
    echo "Building main process..."
    pnpm run build:main
fi

# Start frontend in background
echo "Starting frontend server..."
(cd frontend && pnpm run dev) &
FRONTEND_PID=$!

# Wait for frontend
echo "Waiting for frontend..."
while ! curl -s http://localhost:4521 >/dev/null 2>&1; do
    sleep 1
    echo -n "."
done
echo " Ready!"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Shutting down..."
    kill $FRONTEND_PID 2>/dev/null || true
    pkill -f "node.*vite" 2>/dev/null || true
    exit
}
trap cleanup EXIT INT TERM

# Run Electron with absolute path
echo ""
echo "Starting Crystal..."
ELECTRON_BIN="$CRYSTAL_DIR/node_modules/electron/dist/electron"

if [ ! -f "$ELECTRON_BIN" ]; then
    echo "✗ Electron binary not found at: $ELECTRON_BIN"
    echo "  Running: pnpm install"
    pnpm install
fi

# Launch with explicit environment
echo "Launching: DISPLAY=$DISPLAY $ELECTRON_BIN $CRYSTAL_DIR"
echo ""

# Use exec to replace shell process and ensure environment is passed
exec env DISPLAY=$DISPLAY \
         LIBGL_ALWAYS_INDIRECT=1 \
         ELECTRON_ENABLE_LOGGING=1 \
         NODE_ENV=development \
         "$ELECTRON_BIN" "$CRYSTAL_DIR"