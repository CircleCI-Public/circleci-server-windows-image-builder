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
        
        # Script InstallBashDirectly {
        #     SetScript = {
        #         # Download Git for Windows portable
        #         Write-Host "Downloading Bash Hopefully"
        #         $portableGitPath = "$env:TEMP\PortableGit.exe"
        #         Write-Verbose "Downloading Git for Windows portable..."
        #         Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.39.0.windows.1/PortableGit-2.39.0-64-bit.7z.exe" -OutFile $portableGitPath
                
        #         # Create a directory for extraction
        #         $extractPath = "C:\GitPortable"
        #         if (-not (Test-Path $extractPath)) {
        #             New-Item -Path $extractPath -ItemType Directory -Force
        #         }
                
        #         # Extract the portable Git (self-extracting 7z)
        #         Write-Verbose "Extracting portable Git..."
        #         Start-Process -FilePath $portableGitPath -ArgumentList "-y", "-o$extractPath" -Wait -NoNewWindow
                
        #         # Copy bash.exe directly to System32
        #         Write-Verbose "Copying bash.exe to System32..."
        #         $bashSource = "$extractPath\bin\bash.exe"
        #         if (Test-Path $bashSource) {
        #             # Also copy necessary DLLs
        #             Copy-Item "$extractPath\bin\*.dll" -Destination "$env:windir\System32\" -Force -ErrorAction SilentlyContinue
        #             Copy-Item $bashSource -Destination "$env:windir\System32\bash.exe" -Force
        #         } else {
        #             Write-Error "bash.exe not found in extracted Git portable!"
        #         }
                
        #         # Clean up
        #         Remove-Item $portableGitPath -Force -ErrorAction SilentlyContinue
                
        #         # Create a registry entry to force PATH refresh in all sessions
        #         # This is more reliable than changing environment variables
        #         New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Force | Out-Null
                
        #         Write-Verbose "Bash installation completed"
        #     }
        #     TestScript = {
        #         return (Test-Path "$env:windir\System32\bash.exe")
        #     }
        #     GetScript = {
        #         $exists = Test-Path "$env:windir\System32\bash.exe"
        #         return @{ Result = if ($exists) { "bash.exe exists in System32" } else { "bash.exe not found in System32" } }
        #     }
        # }

        Script FindBash {
            SetScript = {
                # Use Write-Output for guaranteed logging
                Write-Output "BASH_FINDER: Beginning search for bash.exe locations"
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
                        Write-Output "BASH_FINDER_LOCATION: Found bash.exe at $location\bash.exe"
                    } else {
                        Write-Output "BASH_FINDER: No bash.exe at $location"
                    }
                }
                
                # Look through the entire Git directory recursively
                Write-Output "BASH_FINDER: Starting recursive search in Git directory"
                if (Test-Path "C:\Program Files\Git") {
                    $foundBash = Get-ChildItem -Path "C:\Program Files\Git" -Filter "bash.exe" -Recurse -ErrorAction SilentlyContinue
                    foreach ($bash in $foundBash) {
                        $bashPaths += $bash.FullName
                        Write-Output "BASH_FINDER_LOCATION: Found bash.exe at $($bash.FullName)"
                    }
                }
                
                # Print current PATH for debugging
                Write-Output "BASH_FINDER_PATH: Current PATH is $env:Path"
                
                # Try Get-Command to see if it works now
                try {
                    $bashCmd = Get-Command "bash.exe" -ErrorAction Stop
                    Write-Output "BASH_FINDER_SUCCESS: Get-Command found bash.exe at $($bashCmd.Source)"
                } catch {
                    Write-Output "BASH_FINDER_ERROR: Get-Command cannot find bash.exe. Error: $_"
                }
            }
            TestScript = {
                # Always run this script
                return $false
            }
            GetScript = {
                return @{ Result = "Completed bash detection" }
            }
        }

        Script FindBash {
            SetScript = {
                # First install Git if it's not already installed
                if (-not (Test-Path "C:\Program Files\Git")) {
                    Write-Verbose "BASH_FINDER: Git not found, installing now"
                    $installerPath = "$env:TEMP\Git-Installer.exe"
                    Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.49.0/Git-2.49.0-64-bit.exe" -OutFile $installerPath
                    
                    # Install Git with parameters that include bash
                    Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT", 
                                                                       "/NORESTART", 
                                                                       "/COMPONENTS=ext\reg\shellhere,assoc,assoc_sh,gitlfs,bash", 
                                                                       "/PATHOPT=CmdTools" -Wait -NoNewWindow
                    
                    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
                    Write-Verbose "BASH_FINDER: Git installation completed"
                } else {
                    Write-Verbose "BASH_FINDER: Git already installed"
                }
                
                # Now search for bash.exe with distinctive log markers
                Write-Verbose "BASH_FINDER: Beginning search for bash.exe locations"
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
                        Write-Verbose "BASH_FINDER_LOCATION: Found bash.exe at $location\bash.exe"
                    } else {
                        Write-Verbose "BASH_FINDER: No bash.exe at $location"
                    }
                }
                
                # Look through the entire Git directory recursively
                Write-Verbose "BASH_FINDER: Starting recursive search in Git directory"
                if (Test-Path "C:\Program Files\Git") {
                    $foundBash = Get-ChildItem -Path "C:\Program Files\Git" -Filter "bash.exe" -Recurse -ErrorAction SilentlyContinue
                    foreach ($bash in $foundBash) {
                        $bashPaths += $bash.FullName
                        Write-Verbose "BASH_FINDER_LOCATION: Found bash.exe at $($bash.FullName)"
                    }
                }
                
                # Check if bash.exe is already in System32
                if (Test-Path "$env:windir\System32\bash.exe") {
                    Write-Verbose "BASH_FINDER_LOCATION: bash.exe already exists in System32"
                }
                
                # Copy to System32 if found anywhere
                if ($bashPaths.Count -gt 0) {
                    Copy-Item $bashPaths[0] -Destination "$env:windir\System32\bash.exe" -Force
                    Write-Verbose "BASH_FINDER: Copied $($bashPaths[0]) to System32"
                    
                    # Add directory to PATH
                    $bashDir = [System.IO.Path]::GetDirectoryName($bashPaths[0])
                    $envPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                    if ($envPath -notlike "*$bashDir*") {
                        [Environment]::SetEnvironmentVariable("PATH", "$envPath;$bashDir", "Machine")
                        $env:Path = "$env:Path;$bashDir"
                        Write-Verbose "BASH_FINDER: Added $bashDir to PATH"
                    }
                } else {
                    Write-Verbose "BASH_FINDER_ERROR: No bash.exe found in any location!"
                }
                
                # Print current PATH for debugging
                Write-Verbose "BASH_FINDER_PATH: Current PATH is $env:Path"
                
                # Try Get-Command to see if it works now
                try {
                    $bashCmd = Get-Command "bash.exe" -ErrorAction Stop
                    Write-Verbose "BASH_FINDER_SUCCESS: Get-Command found bash.exe at $($bashCmd.Source)"
                } catch {
                    Write-Verbose "BASH_FINDER_ERROR: Get-Command cannot find bash.exe. Error: $_"
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
