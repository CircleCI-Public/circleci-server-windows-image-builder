Configuration CircleBuildHost {
    Import-DscResource -Module CircleCIDSC
    #Import-DscResource -Module cChoco
    Import-DscResource -ModuleName 'PackageManagement' -ModuleVersion '1.0.0.1'
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDsc'
    node localhost {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $False
        }
        CircleUsers "users" { }
        
        Script InstallBash {
            SetScript = {
                # Create directory for bash
                $bashDir = "C:\winbash"
                if (-not (Test-Path $bashDir)) {
                    New-Item -Path $bashDir -ItemType Directory -Force
                }
                
                # Download win-bash
                $zipPath = "$env:TEMP\win-bash.zip"
                Write-Verbose "Downloading win-bash..."
                Invoke-WebRequest -Uri "https://sourceforge.net/projects/win-bash/files/shell-complete/latest/shell-complete.zip/download" -OutFile $zipPath
                
                # Extract the ZIP
                Write-Verbose "Extracting win-bash..."
                Expand-Archive -Path $zipPath -DestinationPath $bashDir -Force
                
                # Verify bash.exe exists and locate it
                $bashExe = Get-ChildItem -Path $bashDir -Filter "bash.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($bashExe) {
                    $bashExePath = $bashExe.DirectoryName
                    Write-Verbose "Found bash.exe at: $($bashExe.FullName)"
                } else {
                    Write-Error "bash.exe not found in extracted files!"
                    throw "bash.exe not found"
                }
                
                # Clean up
                Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
                
                # Add to MACHINE PATH permanently
                $machinePathKey = 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment'
                $oldMachinePath = (Get-ItemProperty -Path $machinePathKey -Name PATH).Path
                if ($oldMachinePath -notlike "*$bashExePath*") {
                    $newMachinePath = "$oldMachinePath;$bashExePath"
                    Set-ItemProperty -Path $machinePathKey -Name PATH -Value $newMachinePath
                    Write-Verbose "Added $bashExePath to machine PATH"
                }
                
                # Also update current process PATH
                $env:Path = "$env:Path;$bashExePath"
                
                # Create a symbolic link in a location that's definitely in PATH
                $windowsDir = "$env:windir\System32"
                if (-not (Test-Path "$windowsDir\bash.exe")) {
                    Copy-Item -Path $bashExe.FullName -Destination "$windowsDir\bash.exe" -Force
                    Write-Verbose "Copied bash.exe to $windowsDir"
                }
                
                # Force a PATH refresh for the current process
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                
                Write-Verbose "bash.exe installation completed and added to PATH"
            }
            TestScript = {
                # First check if it's in System32 (our backup approach)
                if (Test-Path "$env:windir\System32\bash.exe") {
                    return $true
                }
                
                # Otherwise test if it's in PATH
                try {
                    $null = Get-Command "bash.exe" -ErrorAction Stop
                    return $true
                }
                catch {
                    return $false
                }
            }
            GetScript = {
                $bashInSystem32 = Test-Path "$env:windir\System32\bash.exe"
                try {
                    $bashCmd = Get-Command "bash.exe" -ErrorAction SilentlyContinue
                    $bashPath = if ($bashCmd) { $bashCmd.Source } else { "Not found in PATH" }
                    return @{ Result = "Bash: $bashPath, In System32: $bashInSystem32" }
                }
                catch {
                    return @{ Result = "Bash not installed or not in PATH. In System32: $bashInSystem32" }
                }
            }
        }

        Script InstallGit {
            SetScript = {
                $installerPath = "$env:TEMP\Git-Installer.exe"
                Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.39.0.windows.1/Git-2.39.0-64-bit.exe" -OutFile $installerPath
                
                # The "/COMPONENTS" parameter includes bash and "/PATHOPT=Cmd" puts Unix tools in PATH
                Start-Process -FilePath $installerPath -ArgumentList "/SILENT", 
                                                                   "/NORESTART", 
                                                                   "/COMPONENTS=ext\reg\shellhere,assoc,assoc_sh,gitlfs,bash,icons,ext,assoc", 
                                                                   "/PATHOPT=Cmd" -Wait -NoNewWindow
                
                # Clean up and PATH refresh as before
                Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" 
                
                # Log success
                Write-Verbose "Git installation completed"
            }
            TestScript = {
                try {
                    $gitVersion = (git --version 2>&1)
                    return ($gitVersion -like "git version*")
                }
                catch {
                    return $false
                }
            }
            GetScript = {
                try {
                    $gitVersion = (git --version 2>&1)
                    return @{ Result = $gitVersion }
                }
                catch {
                    return @{ Result = "Git not installed" }
                }
            }
        }
        # Install Git LFS
        Script InstallGitLFS {
            SetScript = {
                $installerPath = "$env:TEMP\git-lfs-installer.exe"
                Invoke-WebRequest -Uri "https://github.com/git-lfs/git-lfs/releases/download/v3.3.0/git-lfs-windows-amd64-v3.3.0.exe" -OutFile $installerPath
                Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART" -Wait
                Remove-Item $installerPath -Force
            }
            TestScript = {
                $gitLfsPath = (Get-Command git-lfs -ErrorAction SilentlyContinue).Source
                return ($null -ne $gitLfsPath)
            }
            GetScript = {
                $gitLfsPath = (Get-Command git-lfs -ErrorAction SilentlyContinue).Source
                return @{ Result = if ($null -ne $gitLfsPath) { "Git LFS is installed at: $gitLfsPath" } else { "Git LFS is not installed" } }
            }
            DependsOn = "[Script]InstallGit"
        }
        
        # Install 7zip portable
        Script Install7ZipPortable {
            SetScript = {
                $zipPath = "$env:TEMP\7z-portable.zip"
                $extractPath = "C:\Program Files\7-Zip-Portable"
                Invoke-WebRequest -Uri "https://www.7-zip.org/a/7z2201-x64.zip" -OutFile $zipPath
                
                # Create directory if it doesn't exist
                if (-not (Test-Path $extractPath)) {
                    New-Item -Path $extractPath -ItemType Directory -Force
                }
                
                # Extract using built-in Expand-Archive
                Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
                
                # Add to PATH if not already there
                $envPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                if ($envPath -notlike "*$extractPath*") {
                    [Environment]::SetEnvironmentVariable("PATH", "$envPath;$extractPath", "Machine")
                }
                
                Remove-Item $zipPath -Force
            }
            TestScript = {
                return (Test-Path "C:\Program Files\7-Zip-Portable\7z.exe")
            }
            GetScript = {
                return @{ Result = (Test-Path "C:\Program Files\7-Zip-Portable\7z.exe") }
            }
        }
        
        # Install gzip
        Script InstallGzip {
            SetScript = {
                $zipPath = "$env:TEMP\gzip.zip"
                $extractPath = "C:\Program Files\GZip"
                Invoke-WebRequest -Uri "https://netix.dl.sourceforge.net/project/gnuwin32/gzip/1.3.12-1/gzip-1.3.12-1-bin.zip" -OutFile $zipPath
                
                # Create directory if it doesn't exist
                if (-not (Test-Path $extractPath)) {
                    New-Item -Path $extractPath -ItemType Directory -Force
                }
                
                # Extract using built-in Expand-Archive
                Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
                
                # Add to PATH if not already there
                $envPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                if ($envPath -notlike "*$extractPath\bin*") {
                    [Environment]::SetEnvironmentVariable("PATH", "$envPath;$extractPath\bin", "Machine")
                }
                
                Remove-Item $zipPath -Force
            }
            TestScript = {
                return (Test-Path "C:\Program Files\GZip\bin\gzip.exe")
            }
            GetScript = {
                return @{ Result = (Test-Path "C:\Program Files\GZip\bin\gzip.exe") }
            }
        }
        
        # Install SysInternals
        Script InstallSysInternals {
            SetScript = {
                $zipPath = "$env:TEMP\sysinternals.zip"
                $extractPath = "C:\Program Files\SysInternals"
                Invoke-WebRequest -Uri "https://download.sysinternals.com/files/SysinternalsSuite.zip" -OutFile $zipPath
                
                # Create directory if it doesn't exist
                if (-not (Test-Path $extractPath)) {
                    New-Item -Path $extractPath -ItemType Directory -Force
                }
                
                # Extract using built-in Expand-Archive
                Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
                
                # Add to PATH if not already there
                $envPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                if ($envPath -notlike "*$extractPath*") {
                    [Environment]::SetEnvironmentVariable("PATH", "$envPath;$extractPath", "Machine")
                }
                
                Remove-Item $zipPath -Force
            }
            TestScript = {
                return (Test-Path "C:\Program Files\SysInternals\procmon.exe")
            }
            GetScript = {
                return @{ Result = (Test-Path "C:\Program Files\SysInternals\procmon.exe") }
            }
        }
    }
}

$cd = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )
}
If (-not $(Test-Path -Path '.\CircleBuildHost')) {
    CircleBuildHost -ConfigurationData $cd
}
Update-Paths
Start-DscConfiguration -Path .\CircleBuildHost  -Wait -Force -Verbose
