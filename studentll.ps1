New-LocalUser -Name StudentLL -NoPassword -UserMayNotChangePassword
Set-LocalUser -Name StudentLL -PasswordNeverExpires $true
Add-LocalGroupMember -Group "Users" -Member "StudentLL"
