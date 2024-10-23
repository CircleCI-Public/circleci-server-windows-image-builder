function Test-MachinePath{
    [CmdletBinding()]
    param(
        [string]$PathItem
    )

    $currentPath = Get-MachinePath

    $pathItems = $currentPath.Split(';')

    if($pathItems.Contains($PathItem))
    {
        return $true
    }
    else
    {
        return $false
    }
}

function Set-MachinePath{
    [CmdletBinding()]
    param(
        [string]$NewPath
    )
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name Path -Value $NewPath
    return $NewPath
}

function Add-MachinePathItem
{
    [CmdletBinding()]
    param(
        [string]$PathItem
    )

    $currentPath = Get-MachinePath
    $newPath = $PathItem + ';' + $currentPath
    return Set-MachinePath -NewPath $newPath
}

function Get-MachinePath{
    [CmdletBinding()]
    param(

    )
    $currentPath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
    return $currentPath
}

function Get-SystemVariable{
    [CmdletBinding()]
    param(
        [string]$SystemVariable
    )
    $currentPath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name $SystemVariable).$SystemVariable
    return $currentPath
}

function Set-SystemVariable{
    [CmdletBinding()]
    param(
        [string]$SystemVariable,
        [string]$Value
    )
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name $SystemVariable -Value $Value
    return $Value
}

function Update-Paths {
    [CmdletBinding()]
    param()
    foreach($level in "Machine","User") {
    [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
        # For Path variables, append the new values, if they're not already in there
        if($_.Name -match 'Path$') {
            $_.Value = ($((Get-Content "Env:$($_.Name)") + ";$($_.Value)") -split ';' | Select-Object -unique) -join ';'
        }
        $_
    } | Set-Content -Path { "Env:$($_.Name)" }
    }
}