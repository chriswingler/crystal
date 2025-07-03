#!/bin/bash
# Setup WSL environment for VcXsrv
# This script configures the DISPLAY variable and other X11 settings

echo "Setting up WSL display environment for VcXsrv..."

# Get the Windows host IP from /etc/resolv.conf
WINDOWS_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}')

if [ -z "$WINDOWS_HOST" ]; then
    echo "Error: Could not determine Windows host IP" >&2
    exit 1
fi

# Export display settings
export DISPLAY="${WINDOWS_HOST}:0.0"
export LIBGL_ALWAYS_INDIRECT=1

# Disable WSLg to use VcXsrv instead
unset WAYLAND_DISPLAY

echo "Display configured: DISPLAY=$DISPLAY"

# Test X11 connection
echo "Testing X11 connection..."
if command -v xset &> /dev/null; then
    if xset q &>/dev/null; then
        echo "✓ X11 connection successful!"
    else
        echo "✗ X11 connection failed. Is VcXsrv running?" >&2
        echo ""
        echo "To start VcXsrv on Windows, run:"
        echo "  PowerShell: .\\scripts\\vcxsrv\\start-vcxsrv.ps1"
        echo "  Or double-click: scripts\\vcxsrv\\config.xlaunch"
        exit 1
    fi
else
    echo "Note: xset not installed. Install x11-xserver-utils to test connection."
fi

# Create convenience function for .bashrc/.zshrc
echo ""
echo "To make these settings permanent, add the following to your ~/.bashrc or ~/.zshrc:"
echo ""
echo "# VcXsrv Display Configuration"
echo "export DISPLAY=\$(cat /etc/resolv.conf | grep nameserver | awk '{print \$2; exit;}'):0.0"
echo "export LIBGL_ALWAYS_INDIRECT=1"
echo "unset WAYLAND_DISPLAY"
echo ""

# Offer to append to shell config
read -p "Would you like to append these settings to your shell config? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SHELL_CONFIG=""
    if [ -f "$HOME/.zshrc" ] && [ "$SHELL" = "/bin/zsh" -o "$SHELL" = "/usr/bin/zsh" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_CONFIG" ]; then
        # Check if already configured
        if grep -q "VcXsrv Display Configuration" "$SHELL_CONFIG"; then
            echo "VcXsrv configuration already exists in $SHELL_CONFIG"
        else
            echo "" >> "$SHELL_CONFIG"
            echo "# VcXsrv Display Configuration" >> "$SHELL_CONFIG"
            echo 'export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '\''{print $2; exit;}'\''):0.0' >> "$SHELL_CONFIG"
            echo "export LIBGL_ALWAYS_INDIRECT=1" >> "$SHELL_CONFIG"
            echo "unset WAYLAND_DISPLAY" >> "$SHELL_CONFIG"
            echo "✓ Configuration added to $SHELL_CONFIG"
            echo "  Run 'source $SHELL_CONFIG' to apply changes"
        fi
    else
        echo "Could not determine shell configuration file"
    fi
fi