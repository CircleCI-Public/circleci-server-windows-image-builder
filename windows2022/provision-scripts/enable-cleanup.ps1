<#
.SYNOPSIS
	Enable cleanup script on next shutdown
#>
$ErrorActionPreference="Stop"
New-Item -Path "C:\Windows\Temp\PackerCleanup" -Force
