@echo off
rem Lowest-latency launch: uncapped present (immediate), no swap-interval wait.
rem Expect tearing on fast pans; pacing still follows the console clock.
set ZAKURO_PRESENT_MODE=immediate
set ZAKURO_SWAP_INTERVAL=0
cd /d "%~dp0"
if exist zakuro\target\release\zakuro.exe (goto run)
echo build missing
pause
exit /b 1
:run
start "" "zakuro\target\release\zakuro.exe" "Hatsune Miku - Project Mirai DX (USA).cci"
