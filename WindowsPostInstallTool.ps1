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

$Principal = [WindowsPrincipal][WindowsIdentity]::GetCurrent()
$AdminRole = [WindowsBuiltInRole]::Administrator

# -- CLEANER SELF-ELEVATION --
if (-not $Principal.IsInRole($AdminRole)) {
    exit
}

