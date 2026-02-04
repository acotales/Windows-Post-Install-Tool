<#
.SYNOPSIS
    Windows Post-Installation Utility
.DESCRIPTION
    TODO: Update the description in the future.
.NOTES
    Version: 1.0
    Author: acotales
    Repository: https://github.com/acotales/Windows-Post-Install-Tool
    Instructions:
    - Run via the included Run.bat or directly in PowerShell.
    - Requires an internet connection.
#>

using namespace System.Security.Principal
using namespace System.IO

function Exit-Console {
    try {
        $script:Mutex.ReleaseMutex()
        $script:Mutex.Dispose()
    } catch { }
    # Check raw command line arguments
    $commandLine = [System.Environment]::CommandLine
    if ($commandLine -like "*-NoExit*") {
        Stop-Process -Id $PID -Force
    } else { exit }
}

$CurrentPrincipal = [WindowsPrincipal][WindowsIdentity]::GetCurrent()
$AdminRole = [WindowsBuiltInRole]::Administrator
$MutexName = "Global\" + [Path]::GetFileNameWithoutExtension($PSCommandPath)

$script:Mutex = New-Object System.Threading.Mutex($false, $MutexName)

# -- CLEANER SELF-ELEVATION --
if (-not $CurrentPrincipal.IsInRole($AdminRole)) {
    $ElevationArgs = @{
        FilePath     = "powershell.exe"
        Verb         = "RunAs"
        ArgumentList = "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`""
    }
    Start-Process @ElevationArgs
    exit
}

# -- ENSURE SINGLE INSTANCE --
if (-not $script:Mutex.WaitOne(0, $false)) { Exit-Console }

Register-EngineEvent PowerShell.Exiting -Action {
    try {
        $script:Mutex.ReleaseMutex()
        $script:Mutex.Dispose()
    } catch { }
} | Out-Null
