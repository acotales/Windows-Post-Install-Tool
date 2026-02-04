@echo off

set "URL=https://raw.githubusercontent.com/acotales/Windows-Post-Install-Tool/refs/heads/main/WindowsPostInstallTool.ps1"

:: Check for Administrator privileges
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

if '%errorlevel%' NEQ '0' (
    :: Requesting administrative privileges
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

:: Launch the PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -Command "try { Invoke-RestMethod '%URL%' -ErrorAction Stop | Invoke-Expression } catch { exit 1 }"
