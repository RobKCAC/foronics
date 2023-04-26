Get-LocalUser

$UserAccount = Get-LocalUser -Name "administrator"
$UserAccount | Set-LocalUser -PasswordNeverExpires $true

$UserAccount = Get-LocalUser -Name "localadmin"
$UserAccount | Set-LocalUser -PasswordNeverExpires $true
$UserAccount | Enable-LocalUser

$UserAccount = Get-LocalUser -Name "master"
$UserAccount | Set-LocalUser -PasswordNeverExpires $true
$UserAccount | Enable-LocalUser

$UserAccount = Get-LocalUser -Name "technician"
$UserAccount | Set-LocalUser -PasswordNeverExpires $true
$UserAccount | Enable-LocalUser

Get-LocalUser | FL
