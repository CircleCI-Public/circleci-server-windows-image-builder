Configuration CircleBuildHost {
    Import-DscResource -Module CircleCIDSC
    Import-DscResource -Module cChoco
    Import-DscResource -ModuleName 'PackageManagement' -ModuleVersion '1.0.0.1'
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node localhost {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $False
        }

        CircleUsers "users" { }
        CircleBuildAgentPreReq buildAgentPreReq { }
        CircleCloudTools cloudTools { }
        CircleDevTools devTools { }
        CircleMicrosoftTools MicrosoftTools { }
    }
}

$cd = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )
}
If (-not $(Test-Path -Path '.\CircleBuildHost')) {
    CircleBuildHost -ConfigurationData $cd
}
Update-Paths
Start-DscConfiguration -Path .\CircleBuildHost  -Wait -Force -Verbose

