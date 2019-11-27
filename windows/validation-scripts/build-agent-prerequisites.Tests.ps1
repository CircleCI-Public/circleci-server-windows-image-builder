Describe "Build Agent prerequisites are present" {
    It "Has 7zip on th path" {
        (Get-Command -Name '7z') | Should -HaveCount 1
    }
    It "Has git on the path" {
        (Get-Command -Name 'git') | Should -HaveCount 1
    }
    It "Has unix tools on the path" {
        (Get-Command -Name 'xargs') | Should -HaveCount 1
    }
    It "Has gzip on the path" {
        (Get-Command -Name 'gzip') | Should -HaveCount 1
    }
}

$SoftwareName = "7zip"
$(7z --help).Split([System.Environment]::NewLine)[1] -match "\d+\.\d+"
$7zipVersion = $matches[0]

$Description = @"
_Version:_ $7zipVersion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$SoftwareName = "git"
$gitversion = $(git --version)

$Description = @"
_Version:_ $gitversion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$SoftwareName = "gzip"
$gzipversion = $(gzip --version).Split([System.Environment]::NewLine)[0]

$Description = @"
_Version:_ $gzipversion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description
