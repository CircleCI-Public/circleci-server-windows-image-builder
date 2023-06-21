# Set your Docker registry mirror via the DOCKERHUB_REGISTRY_MIRROR env var.
$registryMirror = echo $Env:DOCKERHUB_REGISTRY_MIRROR
if (-Not $registryMirror) {
    Write-Host "No registry mirror set. Exiting early."
    exit
}

# Check if Docker service is running
$dockerService = Get-Service -Name Docker -ErrorAction SilentlyContinue
if ($dockerService.Status -ne "Running") {
    Write-Host "Docker service is not running."
    exit
}

# Stop Docker service
Stop-Service -Name Docker

# Set the docker configutation
$daemonConfigPath = "C:\ProgramData\Docker\config\daemon.json"

# load or create Docker config JSON
if (Test-Path -Path $daemonConfigPath -PathType Leaf) {
    Write-Host "Docker config JSON exists."
    $daemonConfig = Get-Content -Path $daemonConfigPath | ConvertFrom-Json
} else {
    Write-Host "Docker config JSON does not exist."
    $daemonConfig = @{}
}

# Add or update registry mirror settings
if ($daemonConfig.'registry-mirrors' -eq $null) {
    Write-Host "registry mirror array missing. Creating record.."
    $daemonConfig | add-member -type NoteProperty -Name 'registry-mirrors' -Value @($registryMirror)
} else {
    Write-Host "registry mirror array found. Appending record.."
    $daemonConfig.'registry-mirrors' += $registryMirror
}

# NOT RECOMMENDED: Add or update insecure registry settings
# Uncomment code block below if your Docker registry mirror is not using HTTPS (insecure)
# if ($daemonConfig.'insecure-registries' -eq $null) {
#     Write-Host "insecure-registries array missing. Creating record.."
#     $daemonConfig | add-member -type NoteProperty -Name 'insecure-registries' -Value @($registryMirror)
# } else {
#     Write-Host "insecure-registries array found. Appending record.."
#     $daemonConfig.'insecure-registries' += $registryMirror
# }

# Save the modified configuration file
$daemonConfig | ConvertTo-Json | Set-Content -Path $daemonConfigPath

# inspect config
Get-Content -Path $daemonConfigPath

# Start Docker service
Start-Service -Name Docker

Write-Host "Docker Daemon has been configured to use the registry mirror."