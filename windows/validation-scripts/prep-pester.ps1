$module = "C:\Program Files\WindowsPowerShell\Modules\Pester"
takeown /F $module /A /R
icacls $module /reset
icacls $module /grant Administrators:'F' /inheritance:d /T
Remove-Item -Path $module -Recurse -Force -Confirm:$false

$module = "C:\Program Files (x86)\WindowsPowerShell\Modules\Pester"
takeown /F $module /A /R
icacls $module /reset
icacls $module /grant Administrators:'F' /inheritance:d /T
Remove-Item -Path $module -Recurse -Force -Confirm:$false

Install-Module -Name Pester -Force -RequiredVersion 4.9.0
Update-Module -Name Pester