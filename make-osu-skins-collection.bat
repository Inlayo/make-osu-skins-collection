@echo off
setlocal
cd /d "%~dp0"

where powershell >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo PowerShell is not installed or not available in PATH.
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0make-osu-skins-collection.ps1"
pause
