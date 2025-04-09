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

        Script InstallGitWithBash {
            SetScript = {
                $installerPath = "$env:TEMP\Git-Installer.exe"
                Write-Verbose "Downloading Git for Windows (includes bash)..."
                Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.49.0/Git-2.49.0-64-bit.exe" -OutFile $installerPath
                
                # Install Git with parameters that specifically include bash in PATH
                Write-Verbose "Installing Git with bash..."
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
                
                # Create a direct copy in System32 as a failsafe
                if (Test-Path "C:\Program Files\Git\usr\bin\bash.exe") {
                    Copy-Item "C:\Program Files\Git\usr\bin\bash.exe" -Destination "$env:windir\System32\" -Force
                    Write-Verbose "Copied bash.exe to System32 as a backup"
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
