<#
.SYNOPSIS
  Wait for windows updates to install.
.DESCRIPTION
  This script will trigger auto updates asynchronously and wait until it has completed successfully.
#>
$ErrorActionPreference="Stop"

Install-Module -Name PSWindowsUpdate -Force
Get-WindowsUpdate -AcceptAll
Install-WindowsUpdate -AcceptAll -IgnoreReboot
