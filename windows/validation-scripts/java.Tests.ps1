Write-Output "Installing openJDK12..."
Describe "Java" {
    It "is installed and on the path" {
        (Get-Command -Name 'java')
    }
}

$SoftwareName = "java"
([string]$(java -version 2>&1)).Split([System.Environment]::NewLine)[0] -match "\d+\.\d+\.\d+"
$javaVersion = $matches[0]

$Description = @"
_Version:_ $javaVersion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description
