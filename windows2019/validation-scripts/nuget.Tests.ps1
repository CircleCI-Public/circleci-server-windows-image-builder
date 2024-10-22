Describe "Nuget" {
  It "is installed and on the path" {
    $(Get-Command "nuget").Count | Should -eq 1
  }
}

$SoftwareName = "nuget"
$(nuget).Split([System.Environment]::NewLine)[0] -match "\d+\.\d+\.\d+\.\d+"
$nugetVersion = $matches[0]

$Description = @"
_Version:_ $nugetVersion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description