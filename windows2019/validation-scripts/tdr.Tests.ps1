Describe "Timeout Detection and Recovery" {
    It "Should be disabled" {
        (Get-ItemProperty -Path HKLM:\System\CurrentControlSet\Control\GraphicsDrivers -Name TdrLevel).TdrLevel | Should -Be 0
    }
}
