# For EC2 instances, this enables the "Get Windows Password" button
# in the console for custom AMIs
if (Test-Path -Path "C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1") {
  & C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 -SchedulePerBoot
}
