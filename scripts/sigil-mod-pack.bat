@echo off
setlocal EnableDelayedExpansion

:: === CONFIG ===
set REPO=avarise/valheim
set BRANCH=main
set SCRIPT_NAME=auto-install.ps1
set TEMP_SCRIPT=%TEMP%\valheim_installer.ps1
set SCRIPT_URL=https://raw.githubusercontent.com/%REPO%/%BRANCH%/scripts/%SCRIPT_NAME%

:: === DOWNLOAD POWERSHELL INSTALLER SCRIPT ===
echo Downloading installer script...
powershell -Command ^
  "Invoke-WebRequest -Uri '%SCRIPT_URL%' -OutFile '%TEMP_SCRIPT%' -UseBasicParsing"

if not exist "%TEMP_SCRIPT%" (
    echo Failed to download the PowerShell installer script.
    pause
    exit /b 1
)

:: === RUN INSTALLER ===
echo Running the installer...
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_SCRIPT%"

:: === CLEANUP ===
del "%TEMP_SCRIPT%" >nul 2>&1

echo Done! Press any key to exit.
pause >nul
exit /b 0
