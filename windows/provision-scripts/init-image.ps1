function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force -ErrorAction Continue
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled."
}

function Disable-InternetExplorerWelcomeScreen {
    $AdminKey = "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main"
    New-Item -Path $AdminKey -Value 1 -Force
    Set-ItemProperty -Path $AdminKey -Name "DisableFirstRunCustomize" -Value 1 -Force
    Write-Host "Disabled IE Welcome screen"
}

function Disable-UserAccessControl {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -Force
    Write-Host "User Access Control (UAC) has been disabled."
}


Write-Host "Disable UAC"
Disable-UserAccessControl

Write-Host "Disable IE Welcome Screen"
Disable-InternetExplorerWelcomeScreen

Write-Host "Disable IE ESC"
Disable-InternetExplorerESC

Write-Host "Setting local execution policy"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine  -ErrorAction Continue | Out-Null
Get-ExecutionPolicy -List

Import-Module -Name ImageHelpers -Force

Write-Host "Setup PowerShellGet"
# Set-PSRepository -InstallationPolicy Trusted -Name PSGallery
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Write-Host "Logging available DSC resources"
Get-DscResource | Write-Output

Set-PSRepository -InstallationPolicy Trusted -Name PSGallery
& mkdir 'C:\Program Files\WindowsPowerShell\Modules\cChoco\'
Invoke-WebRequest -Uri 'https://github.com/chocolatey/cChoco/archive/development.zip' -OutFile 'C:\cChoco.zip'
Expand-Archive -LiteralPath 'C:\cChoco.zip' -DestinationPath 'C:\\'
Copy-Item -Path 'C:\cChoco-development\*' -Recurse -Destination 'C:\Program Files\WindowsPowerShell\Modules\cChoco\'
Install-Module -Name ComputerManagementDsc -Force
Install-Module -Name CircleCIDSC -RequiredVersion 1.0.1098 -Force
Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 512000
