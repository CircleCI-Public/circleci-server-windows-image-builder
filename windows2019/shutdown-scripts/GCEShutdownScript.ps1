# GCE-specific shutdown things can go here
if (Test-Path -Path "C:\Windows\Temp\PackerCleanup") {
    Remove-LocalUser -Name "circleci_packer"
    $packerProfile = @(Get-WmiObject -Class Win32_UserProfile).Where{$PSItem.LocalPath -contains 'C:\Users\circleci_packer'}
    $packerProfile | Remove-WmiObject
}
