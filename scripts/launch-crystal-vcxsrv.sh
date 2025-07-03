#!/bin/bash
# Launch Crystal with VcXsrv
# This script ensures VcXsrv is running and launches Crystal with proper display settings

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CRYSTAL_DIR="$(dirname "$SCRIPT_DIR")"

echo "Crystal VcXsrv Launcher"
echo "======================"
echo ""

# Check if we're in WSL
if ! grep -qi microsoft /proc/version; then
    echo "Error: This script is designed to run in WSL" >&2
    exit 1
fi

# Setup display environment
# Use localhost:0.0 which we know works with VcXsrv
export DISPLAY=localhost:0.0
export LIBGL_ALWAYS_INDIRECT=1
echo "Display configured: DISPLAY=$DISPLAY"

# Check if VcXsrv is running on Windows
echo ""
echo "Checking if VcXsrv is running..."
if tasklist.exe 2>/dev/null | grep -qi vcxsrv; then
    echo "✓ VcXsrv is running"
else
    echo "✗ VcXsrv is not running"
    echo ""
    echo "Starting VcXsrv..."
    
    # Try to start VcXsrv using PowerShell
    if command -v powershell.exe &> /dev/null; then
        powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/vcxsrv/start-vcxsrv.ps1"
        
        # Wait a moment for VcXsrv to start
        echo "Waiting for VcXsrv to initialize..."
        sleep 3
        
        # Check again
        if tasklist.exe 2>/dev/null | grep -qi vcxsrv; then
            echo "✓ VcXsrv started successfully"
        else
            echo "✗ Failed to start VcXsrv automatically"
            echo ""
            echo "Please start VcXsrv manually:"
            echo "  1. In Windows Explorer, navigate to: $(wslpath -w "$SCRIPT_DIR/vcxsrv")"
            echo "  2. Double-click: config.xlaunch"
            echo ""
            read -p "Press Enter after starting VcXsrv..."
        fi
    else
        echo "PowerShell not found. Please start VcXsrv manually:"
        echo "  1. In Windows Explorer, navigate to: $(wslpath -w "$SCRIPT_DIR/vcxsrv")"
        echo "  2. Double-click: config.xlaunch"
        echo ""
        read -p "Press Enter after starting VcXsrv..."
    fi
fi

# Navigate to Crystal directory
echo ""
echo "Navigating to Crystal directory..."
cd "$CRYSTAL_DIR"

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "Dependencies not found. Running pnpm install..."
    pnpm install
fi

# Check if main process is built
if [ ! -d "main/dist" ]; then
    echo "Main process not built. Running pnpm run build:main..."
    pnpm run build:main
fi

# Kill any existing Crystal instances
echo ""
echo "Checking for existing Crystal instances..."
if pkill -f "electron.*crystal" 2>/dev/null; then
    echo "✓ Stopped existing Crystal instances"
    sleep 1
fi

# Launch Crystal
echo ""
echo "Launching Crystal..."
echo "==================="
echo ""
echo "Display: $DISPLAY"
echo "Working directory: $(pwd)"
echo ""

# Run Crystal in development mode
pnpm run dev