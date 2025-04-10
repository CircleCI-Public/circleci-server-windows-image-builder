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
                # Use the correct URL for downloading Git
                $gitInstallerUrl = "https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/Git-2.49.0-64-bit.exe"
                $installerPath = "$env:TEMP\Git-Installer.exe"
                
                Write-Output "BASH_FINDER: Attempting to download Git from $gitInstallerUrl"
                
                try {
                    # Try using System.Net.WebClient instead of Invoke-WebRequest
                    $webClient = New-Object System.Net.WebClient
                    $webClient.DownloadFile($gitInstallerUrl, $installerPath)
                    Write-Output "BASH_FINDER: Download completed successfully"
                }
                catch {
                    Write-Output "BASH_FINDER_ERROR: Download failed with error: $_"
                    throw "Unable to download Git installer"
                }
                
                if (Test-Path $installerPath) {
                    # Install Git with parameters that include bash
                    Write-Output "BASH_FINDER: Installing Git with bash..."
                    Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT", 
                                                                     "/NORESTART", 
                                                                     "/COMPONENTS=ext\reg\shellhere,assoc,assoc_sh,gitlfs,bash", 
                                                                     "/PATHOPT=CmdTools" -Wait -NoNewWindow
                    
                    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
                    Write-Output "BASH_FINDER: Git installation completed"
                    
                    # Check if bash.exe exists
                    $gitBashPath = "C:\Program Files\Git\usr\bin\bash.exe"
                    
                    if (Test-Path $gitBashPath) {
                        Write-Output "BASH_FINDER_LOCATION: Found bash.exe at $gitBashPath"
                        
                        # Add to PATH
                        $bashDir = [System.IO.Path]::GetDirectoryName($gitBashPath)
                        $envPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                        if ($envPath -notlike "*$bashDir*") {
                            [Environment]::SetEnvironmentVariable("PATH", "$envPath;$bashDir", "Machine")
                            $env:Path = "$env:Path;$bashDir"
                            Write-Output "BASH_FINDER: Added $bashDir to PATH"
                        }
                        
                        # Remove bash.exe from System32 if it exists
                        if (Test-Path "$env:windir\System32\bash.exe") {
                            Remove-Item "$env:windir\System32\bash.exe" -Force
                            Write-Output "BASH_FINDER: Removed bash.exe from System32"
                        }
                    } else {
                        Write-Output "BASH_FINDER_ERROR: bash.exe not found at expected location $gitBashPath"
                        
                        # Try to find bash.exe elsewhere in Git installation
                        $foundBash = Get-ChildItem -Path "C:\Program Files\Git" -Filter "bash.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($foundBash) {
                            Write-Output "BASH_FINDER_LOCATION: Found alternative bash.exe at $($foundBash.FullName)"
                            
                            # Add to PATH
                            $bashDir = $foundBash.DirectoryName
                            $envPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                            if ($envPath -notlike "*$bashDir*") {
                                [Environment]::SetEnvironmentVariable("PATH", "$envPath;$bashDir", "Machine")
                                $env:Path = "$env:Path;$bashDir"
                                Write-Output "BASH_FINDER: Added $bashDir to PATH"
                            }
                        }
                    }
                    
                    # Check if bash.exe is now available in PATH
                    try {
                        $bashCmd = Get-Command "bash.exe" -ErrorAction Stop
                        Write-Output "BASH_FINDER_SUCCESS: Get-Command found bash.exe at $($bashCmd.Source)"
                    } catch {
                        Write-Output "BASH_FINDER_ERROR: Get-Command cannot find bash.exe. Error: $_"
                    }
                } else {
                    Write-Output "BASH_FINDER_ERROR: Installer not found after download attempt"
                }
            }
            TestScript = {
                # Check if Git is already installed with bash
                if (Test-Path "C:\Program Files\Git\usr\bin\bash.exe") {
                    $bashDir = "C:\Program Files\Git\usr\bin"
                    $envPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                    if ($envPath -like "*$bashDir*") {
                        return $true
                    }
                }
                return $false
            }
            GetScript = {
                $bashPath = "C:\Program Files\Git\usr\bin\bash.exe"
                $exists = Test-Path $bashPath
                return @{ Result = if ($exists) { "Git bash is installed at: $bashPath" } else { "Git bash is not installed" } }
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
