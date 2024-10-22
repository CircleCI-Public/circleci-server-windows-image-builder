Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
$scriptfile = "C:\tmp\provision-scripts\ce\ce.ps1"
$moduledir = "C:\tmp\ce"
$provisionscriptsdir = "C:\tmp\provision-scripts"

Import-Module -Name 'C:\tmp\ce\VSCELicense.psd1'

Write-Output "Before update"
Get-VSCELicenseExpirationDate -Version 2019

# Set the timeout to 31 days
Set-VSCELicenseExpirationDate -Version 2019 -AddDays 31

Write-Output "After update"
Get-VSCELicenseExpirationDate -Version 2019

# Delete the scheduled task
Unregister-ScheduledTask -TaskName "ccitimeout" -Confirm:$false

Remove-Item -Path $scriptfile -Force
Remove-Item $moduledir -Recurse
Remove-Item $provisionscriptsdir -Recurse
 
