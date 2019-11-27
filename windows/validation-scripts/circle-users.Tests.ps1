Describe "Circleci users are set up correctly" {
  $circleUsers = Get-LocalUser | Where-Object Name -clike "circleci*" | Select-Object -ExpandProperty Name
  $circleGroups = Get-LocalGroupMember -Name Administrators | Where-Object Name -like "*circleci*" | Select-Object -ExpandProperty Name
  $domain = $env:COMPUTERNAME
  It "The admin user is present" {
    $circleUsers | Should -Contain "circleci-admin"
  }
  It "The build user is present" {
    $circleUsers | Should -Contain "circleci"
  }
  It "The admin is user is admin" {
    $circleGroups | Should -Contain "$domain\circleci"
  }
  It "The build user is admin" {
    $circleGroups | Should -Contain "$domain\circleci-admin"
  }
}