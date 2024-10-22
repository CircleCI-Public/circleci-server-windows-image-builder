Describe "Python" {
    It "conda is present and on the path" {
        $(Get-Command -Name "conda")
    }

    It "python is present and on the path" {
        $(Get-Command -Name "python")
    }
}

$(python --version) -match "\d+\.\d+\.\d"
$pythonVersion = $matches[0]
$SoftwareName = "python"
$Description = @"
_Version:_ $pythonVersion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description