# Ensures the latest version of PowerShell 7.1 is installed.
$download = "https://github.com/PowerShell/PowerShell/releases/download/v7.1.3/PowerShell-7.1.3-win-x64.msi"
$knownhash = "459642D8B6D69F643794DF8394F28191F43E5ED35472899C4F0D8424F6D1317C"

Invoke-WebRequest -Uri $download -OutFile "pwsh-installer.msi"
$installerhash = Get-FileHash -Path "pwsh-installer.msi" -Algorithm SHA256

if ($installerhash.hash -ne $knownhash) {
    throw "Error! Installer hash and known hash do not match. Exiting."
}

msiexec.exe /package "pwsh-installer.msi" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=0 ENABLE_PSREMOTING=0 REGISTER_MANIFEST=1
