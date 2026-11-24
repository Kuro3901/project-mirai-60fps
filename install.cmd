@echo off
rem install the 60 fps patch for Zakuro (Windows)
setlocal
cd /d "%~dp0"

set "MODS=%APPDATA%\zakuro\mods\0004000000148C00"
if not exist "%MODS%" mkdir "%MODS%"
copy /y "patches\mirai-60fps-v3-camera.ips" "%MODS%\code.ips" >nul
if errorlevel 1 (
    echo install failed - could not write %MODS%\code.ips
    pause
    exit /b 1
)
echo Installed the 60 fps patch (mirai-60fps-v3-camera.ips -> %MODS%\code.ips).
echo.
echo Requirements:
echo   - the game patch works on any Zakuro build
echo   - more than 60 fps needs the patched Zakuro build - see the README
echo   - launch with run-mirai.cmd
pause
