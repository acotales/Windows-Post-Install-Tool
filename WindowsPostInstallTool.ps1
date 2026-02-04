#Requires -Version 5.1

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

using assembly System.Windows.Forms
using namespace System.Windows.Forms
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

function Test-InternetConnection {
    $google = @{ DNS = "8.8.8.8"; URL = "https://www.google.com/generate_204" }
    try {
        $connectionArgs = @{
            ComputerName = $google.DNS
            Count        = 1
            Quiet        = $true
            ErrorAction  = 'SilentlyContinue'
        }
        # Try ping Google's DNS
        if (Test-Connection @connectionArgs) { return $true }
        # Fallback: check Google's lightweight HTTP connectivity URL
        $response = Invoke-WebRequest -Uri $google.URL -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 204) { return $true }
    } catch { }
    return $false
}

# -- SCRIPT VARIABLES --
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
try {
    if (-not $script:Mutex.WaitOne(0, $false)) { Exit-Console }
}
catch [System.Threading.AbandonedMutexException] {
    # Previous process crashed; re-running the script
    $ElevationArgs = @{
        FilePath     = "powershell.exe"
        Verb         = "RunAs"
        ArgumentList = "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`""
    }
    Start-Process @ElevationArgs
    Exit-Console
}

Register-EngineEvent PowerShell.Exiting -Action {
    try {
        $script:Mutex.ReleaseMutex()
        $script:Mutex.Dispose()
    } catch { }
} | Out-Null

# -- LOOP TO ENSURE DEVICE HAS INTERNET CONNECTION --
$hasInternetConnection = Test-InternetConnection

do {
    if ($hasInternetConnection) { break }

    # No internet connection message box
    $response = [MessageBox]::Show(
        $null,
        "Please check your internet connection",
        "No Internet Connection",
        [MessageBoxButtons]::RetryCancel,
        [MessageBoxIcon]::Information
    )
    
    if ($response -eq "Cancel") { Exit-Console }

    $hasInternetConnection = Test-InternetConnection

} until ($hasInternetConnection)