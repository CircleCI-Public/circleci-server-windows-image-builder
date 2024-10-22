Describe "choco is installed" {
    It "And on the path" {
        (Get-Command -Name 'choco') | Should -HaveCount 1
    }
}

$SoftwareName = "Chocolatey"
$chocoVersion = $(choco --version)
$Description = @"
_Version:_ $chocoVersion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description
