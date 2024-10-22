$ErrorActionPreference = "Stop"
Describe "sshd" {
    # Want to wait until we figure how to keep ssh working through restarts
 #   It "is running and installed" {
 #       $(Get-Service sshd | Select-Object -ExpandProperty Status) | Should -Eq "Running"
 #   }
 #   It "default shell is bash.exe" {
 #       $BashCommand = Get-Command "bash.exe"
 #       Get-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" | Should -Eq $BashCommand.Source
 #   }
}
