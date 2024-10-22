Describe "NVM" {
    It "is installed" {
        $(Get-Command -Name "nvm").Count | Should -Eq 1
    }
    It "has node 12 installed and set to default" {
        $(nvm list)[1] | Should -Match "\* 12.11.1"
    }
}

Describe "yarn" {
    It "is installed" {
        $(Get-Command -Name "yarn").Count | Should -Eq 1
    }
}

$SoftwareName = "nvm"
$version = $(nvm version)

$Description = @"
_Version:_ $version<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$SoftwareName = "yarn"
$version = $(yarn --version)

$Description = @"
_Version:_ $version<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description
