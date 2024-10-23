Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
$destdir = 'c:\tmp\ce'

Write-Output "current dir: $PSScriptRoot"
New-Item -ItemType Directory -Force -Path $destdir
git clone https://github.com/beatcracker/VSCELicense.git $destdir
Push-Location $destdir -StackName cedir
git checkout 4e3d6f4fdab1f960e7bfa298ae501a2b1ab3843c
Pop-Location -StackName cedir
Write-Output "current dir now: $PSScriptRoot" 

$schAction = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument '-NoProfile -WindowStyle Hidden -File "c:\tmp\provision-scripts\ce\ce.ps1"'
$schTrigger = New-ScheduledTaskTrigger -AtStartup
$schPrincipal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount
Register-ScheduledTask -Action $schAction -Trigger $schTrigger -TaskName "ccitimeout" -Description "Scheduled Task to run vs  configuration Script At Startup" -Principal $schPrincipal