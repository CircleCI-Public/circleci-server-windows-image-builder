<#
.SYNOPSIS
  Final cleanup for the base windows VM
.DESCRIPTION
  Perform any additional cleanup we'd like to do on the vm (ie Disable WinRM)
#>
$ErrorActionPreference="Stop"

# Disable WinRM - It's enabled by GCE and we're not using so let's disable it.
Disable-PSRemoting -Force
Stop-Service WinRM
Set-Service WinRM -StartupType Disabled
Set-NetFirewallRule -DisplayName 'Windows Remote Management (HTTP-In)' -Enabled False
