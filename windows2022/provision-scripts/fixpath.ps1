Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Remove Java 1.8 and old versions of GoLang from system Path
Write-Host "Removing Java 1.8 and old verions of GoLang from system Path"
Write-Host "PATH before removal: $env:path"
Remove-ItemFromPath 'C:\Program Files\Eclipse Foundation\jdk-8.0.302.8-hotspot\bin'
Remove-ItemFromPath 'C:\Go\bin'
Write-Host "PATH after removal: $env:path"