Describe "Developer tools" {
    It "Has nunit3-console on th path" {
        (Get-Command -Name 'nunit3-console') | Should -HaveCount 1
    }
    It "Has nano on the path" {
        (Get-Command -Name 'nano') | Should -HaveCount 1
    }
    It "Has vim on the path" {
        (Get-Command -Name 'vim') | Should -HaveCount 1
    }
    It "Has jq on the path" {
        (Get-Command -Name 'jq') | Should -HaveCount 1
    }
}

$SoftwareName = "nunit"
$(nunit3-console --version).Split([System.Environment]::NewLine)[0] -match "\d+\.\d+\.\d+"
$nunitVersion = $matches[0]

$Description = @"
_Version:_ $nunitVersion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$SoftwareName = "nano"

$(nano --version).Split([System.Environment]::NewLine)[0] -match "\d+\.\d+"
$nanoVersion = $matches[0]

$Description = @"
_Version:_ $nanoVersion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$SoftwareName = "vim"

$(vim --version).Split([System.Environment]::NewLine)[0] -match "\d+\.\d+"
$vimVersion = $matches[0]

$Description = @"
_Version:_ $vimVersion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

$SoftwareName = "jq"

$jqVersion = $(jq --version)

$Description = @"
_Version:_ $jqVersion<br/>
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description

