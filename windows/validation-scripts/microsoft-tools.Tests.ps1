Describe ".net" {
  It "the dotnet cli tool is on the path" {
    $(Get-Command -Name 'dotnet') | Should -HaveCount 1
  }
  It "4 versions of the sdk are installed" {
    $(dotnet --list-sdks).Split([System.Environment]::NewLine).Count | Should -EQ 2
  }
  It "12 versions of the runtime are installed" {
    $(dotnet --list-runtimes).Split([System.Environment]::NewLine).Count | Should -EQ 9
  }
}

Describe "The visualstudio build tools" {
  It "is installed" {
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin" | Should -Exist
  }
  It "is on the path" {
    $(Get-Command -Name "msbuild").Count | Should -Eq 1
  }
}

Describe "The Windows sdk" {
  It "is installed" {
    "$Env:Programfiles (x86)\Windows Kits\10" | Should -Exist
    #NOTE TODO! I can't find evidence for sdk 10.1
  }
}

Describe "Visual studio" {
  It "is Installed and locateable" {
    $(& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe") -match "displayName" | Should -Match "Visual Studio Community 2019"
  }
}

Describe "Developer Mode" {
  It "is enabled" {
    $(Get-Item "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock").GetValue("AllowDevelopmentWithoutDevLicense") | should -Eq 1
  }
}

Describe "WinAppDriver" {
  It "is installed" {
    "C:\Program Files (x86)\Windows Application Driver" | Should -Exist
  }
  It "is on the path" {
    $(Get-Command -Name "winappDriver")
  }
}

$SoftwareName = ".net SDK"
$dotNetSdks = $(dotnet --list-sdks)

$Description = @"
_Versions:_ $dotNetSdks <br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$SoftwareName = ".net runtime"
$dotNetRuntimes = $(dotnet --list-runtimes)

$Description = @"
_Versions:_ $dotNetRuntimes <br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

# Adding description of the software to Markdown
$SoftwareName = "WinAppDriver"
$version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("C:\Program Files (x86)\Windows Application Driver\WinAppDriver.exe").FileVersion
$Description = @"
_Version:_ $version<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$SoftwareName = "Visual Studio 2019"
$version = $(& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe") -match "installationVersion"
$version_string = $version -match "\d+\.\d+\.\d+\.\d+"
$Description = @"
_Version:_ $version_string<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$SoftwareName = "windows sdk 10.0"
$Description = @"
_Version:_ 10.0.26624<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$SoftwareName = "windows sdk 10.1"
$Description = @"
_Version:_ 10.1.18362<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description
