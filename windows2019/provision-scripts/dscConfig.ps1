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

        Script InstallGitWithBash {
             SetScript = {
                 $installerPath = "$env:TEMP\Git-Installer.exe"
                 Write-Host "Downloading Git for Windows (includes bash)..."
                 Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.49.0/Git-2.49.0-64-bit.exe" -OutFile $installerPath
 
                 # Install Git with parameters that specifically include bash in PATH
                 Write-Host "Installing Git with bash..."
                 Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT", 
                                                                    "/NORESTART", 
                                                                    "/COMPONENTS=ext\reg\shellhere,assoc,assoc_sh,gitlfs,bash", 
                                                                    "/PATHOPT=CmdTools" -Wait -NoNewWindow
 
                 # Clean up
                 Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
 
                 # Explicitly add Git's bin and usr/bin to the PATH
                 $gitBinPath = "C:\Program Files\Git\bin"
                 $gitUsrBinPath = "C:\Program Files\Git\usr\bin"
 
                 # Update system PATH
                 $envPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                 if ($envPath -notlike "*$gitBinPath*") {
                     [Environment]::SetEnvironmentVariable("PATH", "$envPath;$gitBinPath;$gitUsrBinPath", "Machine")
                 }
 
                 # Update current session PATH
                 $env:Path = "$env:Path;$gitBinPath;$gitUsrBinPath"
                 [Environment]::SetEnvironmentVariable('PATH', "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));C:\Program Files\Git\usr\bin\bash.exe", 'Machine')
                 Write-Host "BASH added to PATH"
 
                 # Create a direct copy in System32 as a failsafe
                 if (Test-Path "C:\Program Files\Git\usr\bin\bash.exe") {
                     Copy-Item "C:\Program Files\Git\usr\bin\bash.exe" -Destination "$env:windir\System32\" -Force
                     Write-Host "Copied bash.exe to System32 as a backup"
                 }
             }
             TestScript = {
                 # Check for bash in multiple locations
                 if (Test-Path "C:\Program Files\Git\usr\bin\bash.exe") {
                     return $true
                 }
                 return $false
             }
             GetScript = {
                 $bashPath = if (Test-Path "C:\Program Files\Git\usr\bin\bash.exe") { 
                     "C:\Program Files\Git\usr\bin\bash.exe" 
                 } else { 
                     "Not found" 
                 }
 
                 return @{ Result = "Bash is installed at: $bashPath" }
             }
         }

        Script FindBash {
            SetScript = {
                # First install Git if it's not already installed
                if (-not (Test-Path "C:\Program Files\Git")) {
                    Write-Host "BASH_FINDER: Git not found, installing now"
                    $installerPath = "$env:TEMP\Git-Installer.exe"
                    Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/Git-2.49.0-64-bit.exe" -OutFile $installerPath
                    
                    # Install Git with parameters that include bash
                    Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT", 
                                                                       "/NORESTART", 
                                                                       "/COMPONENTS=ext\reg\shellhere,assoc,assoc_sh,gitlfs,bash", 
                                                                       "/PATHOPT=CmdTools" -Wait -NoNewWindow
                    
                    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
                    Write-Host "BASH_FINDER: Git installation completed"
                } else {
                    Write-Host "BASH_FINDER: Git already installed"
                }
                
                # Now search for bash.exe with distinctive log markers
                Write-Host "BASH_FINDER: Beginning search for bash.exe locations"
                $bashPaths = @()
                
                # Check common locations
                $locations = @(
                    "C:\Program Files\Git\bin",
                    "C:\Program Files\Git\usr\bin",
                    "C:\Program Files\Git\mingw64\bin",
                    "C:\Program Files (x86)\Git\bin",
                    "C:\Program Files (x86)\Git\usr\bin"
                )
                
                foreach ($location in $locations) {
                    if (Test-Path "$location\bash.exe") {
                        $bashPaths += "$location\bash.exe"
                        Write-Host "BASH_FINDER_LOCATION: Found bash.exe at $location\bash.exe"
                    } else {
                        Write-Host "BASH_FINDER: No bash.exe at $location"
                    }
                }
                
                # Look through the entire Git directory recursively
                Write-Host "BASH_FINDER: Starting recursive search in Git directory"
                if (Test-Path "C:\Program Files\Git") {
                    $foundBash = Get-ChildItem -Path "C:\Program Files\Git" -Filter "bash.exe" -Recurse -ErrorAction SilentlyContinue
                    foreach ($bash in $foundBash) {
                        $bashPaths += $bash.FullName
                        Write-Host "BASH_FINDER_LOCATION: Found bash.exe at $($bash.FullName)"
                    }
                }
                
                # Check if bash.exe is already in System32
                if (Test-Path "$env:windir\System32\bash.exe") {
                    Write-Host "BASH_FINDER_LOCATION: bash.exe already exists in System32"
                }
                
                # Copy to System32 if found anywhere
                if ($bashPaths.Count -gt 0) {
                    Copy-Item $bashPaths[0] -Destination "$env:windir\System32\bash.exe" -Force
                    Write-Host "BASH_FINDER: Copied $($bashPaths[0]) to System32"
                    
                    # Add directory to PATH
                    $bashDir = [System.IO.Path]::GetDirectoryName($bashPaths[0])
                    $envPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                    if ($envPath -notlike "*$bashDir*") {
                        [Environment]::SetEnvironmentVariable("PATH", "$envPath;$bashDir", "Machine")
                        $env:Path = "$env:Path;$bashDir"
                        Write-Host "BASH_FINDER: Added $bashDir to PATH"
                    }
                } else {
                    Write-Host "BASH_FINDER_ERROR: No bash.exe found in any location!"
                }
                
                # Print current PATH for debugging
                Write-Host "BASH_FINDER_PATH: Current PATH is $env:Path"
                
                # Try Get-Command to see if it works now
                try {
                    $bashCmd = Get-Command "bash.exe" -ErrorAction Stop
                    Write-Host "BASH_FINDER_SUCCESS: Get-Command found bash.exe at $($bashCmd.Source)"
                } catch {
                    Write-Host "BASH_FINDER_ERROR: Get-Command cannot find bash.exe. Error: $_"
                }
            }
            TestScript = {
                # Always run this script
                return $false
            }
            GetScript = {
                return @{ Result = "Completed bash detection" }
            }
            DependsOn = "[Script]InstallGitWithBash"
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
            DependsOn = "[Script]InstallGitWithBash"
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
