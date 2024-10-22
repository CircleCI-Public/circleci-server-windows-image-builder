Describe "Build Agent prerequisites are present" {
    It "Has aws on th path" {
        (Get-Command -Name 'aws') | Should -HaveCount 1
    }
    It "Has azure cli on the path" {
        (Get-Command -Name 'az') | Should -HaveCount 1 
    }
    It "Has WebPiCmd on the path" {
        (Get-Command -Name 'webpicmd') | Should -HaveCount 1 
    }
    It "Has Azure service fabric installed" {
        (Get-Command -Name 'gzip') | Should -HaveCount 1 
    }
}

# Cloud Tools 
$SoftwareName = "aws"
$awsversion = $(aws --version)

$Description = @"
_Version:_ $awsversion <br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$SoftwareName = "Azure CLI"
$azversion = $(az --version).Split([System.Environment]::NewLine)[0]

$Description = @"
_Version:_ $azversion <br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$piInstalled = $(webpicmd /List /ListOption:Installed).Split([System.Environment]::NewLine)
$serviceFabricVersion = $piInstalled | Where-Object { $_ -match "Azure-Service*" }

$SoftwareName = "Azure Service Fabric"
$Description = @"
_Version:_ $serviceFabricVersion <br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description
