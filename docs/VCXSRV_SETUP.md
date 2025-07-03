# VcXsrv Setup Guide for Crystal on WSL

This guide will help you set up VcXsrv as an alternative to WSLg for running Crystal with better window management and performance on Windows.

## Why VcXsrv?

While WSLg (Windows Subsystem for Linux GUI) works out of the box, VcXsrv offers several advantages for Electron applications like Crystal:

- **Better window resizing** - No issues with frozen or unresponsive window borders
- **Proper window management** - Individual taskbar entries for each window
- **Better performance** - Lower latency and smoother rendering
- **More configuration options** - Fine-tune display settings for your needs

## Prerequisites

- Windows 10/11 with WSL2 installed
- Crystal repository cloned in WSL
- VcXsrv installed on Windows (see installation below)

## Installation

### 1. Download VcXsrv

Download the latest VcXsrv installer from the maintained fork:
- https://github.com/marchaesen/vcxsrv/releases
- Download `vcxsrv-64.21.1.13.0.installer.exe` (or latest version)
- Run the installer with default options

### 2. Configure Windows Firewall

VcXsrv needs to accept connections from WSL:

1. Open Windows Defender Firewall
2. Click "Allow an app or feature through Windows Defender Firewall"
3. Find "VcXsrv windows xserver" in the list
4. Check both "Private" and "Public" boxes
5. Click OK

Alternatively, you can run this PowerShell command as Administrator:
```powershell
New-NetFirewallRule -DisplayName "VcXsrv" -Direction Inbound -Program "C:\Program Files\VcXsrv\vcxsrv.exe" -Action Allow
```

## Configuration

### 1. Create VcXsrv Configuration

Save this configuration as `crystal-vcxsrv.xlaunch` in your Windows user directory:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<XLaunch 
    WindowMode="MultiWindow" 
    ClientMode="NoClient" 
    LocalClient="False" 
    Display="-1" 
    LocalProgram="xcalc" 
    RemoteProgram="xterm" 
    RemotePassword="" 
    PrivateKey="" 
    RemoteHost="" 
    RemoteUser="" 
    XDMCPHost="" 
    XDMCPBroadcast="False" 
    XDMCPIndirect="False" 
    Clipboard="True" 
    ClipboardPrimary="True" 
    ExtraParams="-ac -nowgl -dpms" 
    Wgl="False" 
    DisableAC="False" 
    XDMCPTerminate="False"/>
```

### 2. Configure WSL Environment

Add the following to your `~/.bashrc` or `~/.zshrc` in WSL:

```bash
# VcXsrv Display Configuration
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}'):0.0

# Disable WSLg (use VcXsrv instead)
export DISPLAY_ORIG=$DISPLAY
unset WAYLAND_DISPLAY

# X11 Performance Settings
export LIBGL_ALWAYS_INDIRECT=1

# Electron-specific optimizations
export ELECTRON_ENABLE_LOGGING=1
```

Then reload your shell configuration:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

### 3. Test the Connection

1. Start VcXsrv by double-clicking the `crystal-vcxsrv.xlaunch` file
2. In WSL, test the connection:
   ```bash
   # Install x11-apps if not already installed
   sudo apt update
   sudo apt install x11-apps
   
   # Test with a simple X11 application
   xclock
   ```

If you see a clock window, VcXsrv is working correctly!

## Running Crystal with VcXsrv

### Method 1: Manual Launch

1. Start VcXsrv using the `.xlaunch` file
2. In WSL, navigate to Crystal directory and run:
   ```bash
   cd ~/proj/crystal
   pnpm run dev
   ```

### Method 2: Using Launch Script

Use the provided launch script for convenience:
```bash
~/proj/crystal/scripts/launch-crystal-vcxsrv.sh
```

This script will:
- Check if VcXsrv is running and start it if needed
- Set up the display environment
- Launch Crystal with optimal settings

## Troubleshooting

### "Cannot open display" Error

1. Check if VcXsrv is running:
   ```bash
   tasklist.exe | grep -i vcxsrv
   ```

2. Verify DISPLAY variable:
   ```bash
   echo $DISPLAY
   # Should show something like: 172.23.144.1:0.0
   ```

3. Test connectivity:
   ```bash
   nc -zv $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}') 6000
   ```

### Window Scaling Issues

If Crystal appears too small or too large:

1. Create `~/.Xresources` in WSL:
   ```bash
   Xft.dpi: 96
   ```

2. Load the settings:
   ```bash
   xrdb -merge ~/.Xresources
   ```

3. For HiDPI displays, you may need to adjust:
   ```bash
   Xft.dpi: 144  # or 192 for 4K displays
   ```

### Clipboard Not Working

Ensure VcXsrv was started with clipboard support. The provided `.xlaunch` configuration includes:
- `Clipboard="True"`
- `ClipboardPrimary="True"`

### Performance Issues

1. Disable hardware acceleration in VcXsrv (already done in our config with `-nowgl`)
2. Try disabling indirect rendering:
   ```bash
   export LIBGL_ALWAYS_INDIRECT=0
   ```

## Advanced Configuration

### Auto-start VcXsrv with Windows

1. Press `Win + R`, type `shell:startup`
2. Copy the `crystal-vcxsrv.xlaunch` file to this folder
3. VcXsrv will now start automatically when Windows boots

### Multiple Monitor Support

For better multi-monitor support, modify the `.xlaunch` file:
```xml
ExtraParams="-ac -nowgl -dpms -multiwindow -screen 0 @1"
```

This pins VcXsrv to your primary monitor.

## Switching Back to WSLg

If you want to switch back to WSLg:

1. Comment out the VcXsrv configuration in your shell config:
   ```bash
   # export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}'):0.0
   # unset WAYLAND_DISPLAY
   ```

2. Restart your WSL terminal
3. WSLg will automatically take over

## Performance Comparison

| Feature | WSLg | VcXsrv |
|---------|------|---------|
| Setup Complexity | None (built-in) | Moderate |
| Window Resizing | Often buggy | Smooth |
| Clipboard | Automatic | Configured |
| GPU Acceleration | Yes | Limited |
| CPU Usage | Higher | Lower |
| Latency | Higher | Lower |
| Best For | Simple apps | Electron apps |

For Crystal and other Electron applications, VcXsrv generally provides a better experience despite the additional setup required.