<#
.SYNOPSIS
Disable Windows Defender's scanner to optimize I/O.
.DESCRIPTION
By default Windows Defender scans literally all network traffic and any disk IO operations (ie: gzip), which slows down
many CI use cases and isn't critical from a security perspective. We disable that
by default but give users the option to turn it back on if they want.
#>
$ErrorActionPreference="Stop"

Set-MpPreference -DisableRealtimeMonitoring $true
