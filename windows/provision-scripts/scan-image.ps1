################################################################################
##  File:  Run-Antivirus.ps1
##  Desc:  Run a full antivirus scan.
##         Run right after cleanup before we sysprep
################################################################################

Write-Host "Run antivirus"

# Tell Defender to use 100% of the CPU during the scan
Set-MpPreference -ScanAvgCPULoadFactor 100

Write-Output "Running Scan"
$job = Invoke-Command -ComputerName localhost -AsJob -ScriptBlock {
    Push-Location "C:\Program Files\Windows Defender"
    .\MpCmdRun.exe -Scan -ScanType 2
    Pop-Location
}

While (($job.State -eq "Running")) {
  Write-Host '.'
  Start-Sleep -Seconds 60
}

Write-Output "Done Scanning"

Write-Host "Set antivirus parmeters"
Set-MpPreference -ScanAvgCPULoadFactor 5 `
                 -ExclusionPath "C:\"
