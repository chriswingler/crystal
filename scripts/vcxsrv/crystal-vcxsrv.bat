@echo off
REM Crystal VcXsrv Launcher for Windows
REM This batch file starts VcXsrv and provides instructions for running Crystal

echo Crystal VcXsrv Launcher
echo =======================
echo.

REM Check if VcXsrv is installed
if not exist "C:\Program Files\VcXsrv\vcxsrv.exe" (
    echo ERROR: VcXsrv not found at C:\Program Files\VcXsrv\vcxsrv.exe
    echo.
    echo Please install VcXsrv from:
    echo https://github.com/marchaesen/vcxsrv/releases
    echo.
    pause
    exit /b 1
)

REM Check if VcXsrv is already running
tasklist /FI "IMAGENAME eq vcxsrv.exe" 2>NUL | find /I /N "vcxsrv.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo VcXsrv is already running.
    echo.
    echo To restart VcXsrv:
    echo 1. Right-click the X icon in your system tray
    echo 2. Click "Exit"
    echo 3. Run this batch file again
    echo.
    goto :instructions
)

REM Start VcXsrv
echo Starting VcXsrv...
cd /d "%~dp0"
if exist "config-electron.xlaunch" (
    echo Using Electron-optimized configuration...
    start "" "config-electron.xlaunch"
) else (
    echo Starting with default parameters...
    start "" "C:\Program Files\VcXsrv\vcxsrv.exe" -multiwindow -clipboard -ac -nowgl -dpms
)

REM Wait for VcXsrv to start
timeout /t 3 /nobreak >nul

REM Check if it started successfully
tasklist /FI "IMAGENAME eq vcxsrv.exe" 2>NUL | find /I /N "vcxsrv.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo SUCCESS: VcXsrv is now running!
) else (
    echo ERROR: VcXsrv failed to start.
    echo Please check Windows Event Viewer for errors.
    pause
    exit /b 1
)

:instructions
echo.
echo ========================================
echo To run Crystal from WSL:
echo ========================================
echo.
echo 1. Open WSL terminal
echo.
echo 2. Run one of these commands:
echo.
echo    Option A - Quick test (recommended):
echo    ./scripts/run-crystal-direct.sh
echo.
echo    Option B - With npm scripts:
echo    export DISPLAY=localhost:0.0
echo    pnpm run dev
echo.
echo    Option C - Debug mode:
echo    ./scripts/vcxsrv/debug-display.sh
echo    ./scripts/vcxsrv/electron-wrapper.sh
echo.
echo ========================================
echo.
echo Troubleshooting:
echo - If Crystal doesn't open, run: ./scripts/vcxsrv/debug-display.sh
echo - Make sure Windows Firewall allows VcXsrv
echo - Try different DISPLAY values: localhost:0.0, :0, or 127.0.0.1:0.0
echo.
pause