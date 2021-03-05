Describe "CircleCI users are set up correctly" {
  It "The admin user is present" {
    Get-LocalUser -Name circleci-admin | Should -HaveCount 1
  }
  It "The build user is present" {
    Get-LocalUser -Name circleci | Should -HaveCount 1
  }
  It "The admin is user is admin" {
    Get-LocalGroupMember -Group Administrators | Where-Object Name -Like "*circleci-admin" | Should -HaveCount 1
  }
  It "The build user is admin" {
    Get-LocalGroupMember -Group Administrators | Where-Object Name -Like "*circleci" | Should -HaveCount 1
  }
}
