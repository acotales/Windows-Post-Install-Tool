@echo off
:: Check for Administrator privileges
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

:: Launch the PowerShell script
@REM echo Starting Windows Post-Install Tool...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0WindowsPostInstallTool.ps1"
@REM pause
