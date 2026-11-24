@echo off
rem launch Zakuro on the Mirai ROM (shows errors, pauses on exit)
setlocal
cd /d "%~dp0"

rem close any other instance first: two Zakuros on one ROM fight over the save
tasklist /fi "imagename eq zakuro.exe" 2>nul | find /i "zakuro.exe" >nul && (
    echo Closing a running Zakuro...
    taskkill /im zakuro.exe /f >nul 2>&1
    timeout /t 2 /nobreak >nul
)

if not exist "Hatsune Miku - Project Mirai DX (USA).cci" (
    echo Put this launcher next to the game's .cci, or edit this file.
    pause
    exit /b 1
)

if not exist "zakuro\target\release\zakuro.exe" (
    echo No zakuro build found at zakuro\target\release\zakuro.exe
    echo See the README for building it, or point this file at your zakuro.exe.
    pause
    exit /b 1
)

"zakuro\target\release\zakuro.exe" "Hatsune Miku - Project Mirai DX (USA).cci"
