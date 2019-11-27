# instance restarts many times while running scripts
# this check makes sure we only turn off winRM at the end
if (Test-Path -Path "C:\Windows\Temp\PackerCleanup") {
  Disable-PSRemoting -Force
  Stop-Service WinRM
  Set-Service WinRM -StartupType Disabled
  Disable-NetFirewallRule -Direction Inbound
  New-NetFirewallRule -DisplayName "Allow GCE Metadata" -Direction Inbound -LocalPort Any -RemotePort Any -Protocol Any -RemoteAddress '169.254.169.254' -LocalAddress Any
  # vm-service uses SSH on port 22. build-agent uses 54782
  New-NetFirewallRule -DisplayName "Allow SSH" -Direction Inbound -LocalPort 22,54782 -RemotePort Any -Protocol TCP -RemoteAddress Any -LocalAddress Any
  Remove-Item -Path "C:\Windows\Temp\PackerCleanup" -Force
}
