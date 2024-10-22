Describe "Environment is configured appropriately" {
    It "Has Defender disabled" {
        (Get-MpPreference).DisableRealtimeMonitoring | Should -Be $true
    }
}
