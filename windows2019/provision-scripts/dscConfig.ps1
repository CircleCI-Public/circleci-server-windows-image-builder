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

        #By default, this installs the required dependencies for a CircleCI job to run. 
        #Things such as the AWS CLI, Python, Golang will not be installed by default. 
        #Please uncomment anything you would like to have installed by default.
        #CircleUsers and CircleBuildAgentPreReq are required.

        CircleUsers "users" { } # https://github.com/CircleCI-Public/CircleCIDSC/blob/main/DSCResources/CircleUsers/CircleUsers.schema.psm1
        CircleBuildAgentPreReq buildAgentPreReq { } # https://github.com/CircleCI-Public/CircleCIDSC/blob/main/DSCResources/CircleBuildAgentPreReq/CircleBuildAgentPreReq.schema.psm1
        #CircleCloudTools cloudTools { } # https://github.com/CircleCI-Public/CircleCIDSC/blob/main/DSCResources/CircleCloudTools/CircleCloudTools.schema.psm1
        #CircleDevTools devTools { } # https://github.com/CircleCI-Public/CircleCIDSC/blob/main/DSCResources/CircleDevTools/CircleDevTools.schema.psm1
        #CircleTDR tdr { } # https://github.com/CircleCI-Public/CircleCIDSC/blob/main/DSCResources/CircleTDR/CircleTDR.schema.psm1
        #CircleMicrosoftTools MicrosoftTools { } # https://github.com/CircleCI-Public/CircleCIDSC/blob/main/DSCResources/CircleMicrosoftTools/CircleMicrosoftTools.schema.psm1
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

