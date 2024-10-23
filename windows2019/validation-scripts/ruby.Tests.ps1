Write-Output "Installing ruby..."
Describe "Ruby" {
    It "is installed" {
        $(Get-Command "ruby").Count | Should -Eq 1
    }
}

$SoftwareName = "ruby"
$(ruby --version) -match "\d+\.\d+\.\d+p\d+"
$rubyVersion= $matches[0]

$Description = @"
_Version:_ $rubyVersion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description