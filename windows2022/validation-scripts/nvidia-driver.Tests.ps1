Describe "Nvidia Drivers" {
    It "Should be installed if a gpu is present" {
        if ((Get-WmiObject Win32_VideoController | ForEach-Object { $_.Name } | Select-String NVIDIA).Count -ne 0) {
            "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe" | Should -Exist
        }
    }
}

Describe "cuDNN" {
    It "Should be installed if a gpu is present" {
        if ((Get-WmiObject Win32_VideoController | ForEach-Object { $_.Name } | Select-String NVIDIA).Count -ne 0) {
            'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.1\bin\cudnn64_7.dll' | Should -Exist
            'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.1\include\cudnn.h' | Should -Exist
            'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.1\lib\x64\cudnn.lib' | Should -Exist
        }
    }
}

if ((Get-WmiObject Win32_VideoController | ForEach-Object { $_.Name } | Select-String NVIDIA).Count -ne 0) {
    # Adding description of the software to Markdown
    $SoftwareName = "Nvidia Driver Version"
    $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe").FileVersion
    $Description = @"
_Version:_ $version<br/>
"@

    Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description
}