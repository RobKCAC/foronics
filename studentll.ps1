New-LocalUser -Name StudentLL -NoPassword -UserMayNotChangePassword
Set-LocalUser -Name StudentLL -PasswordNeverExpires $true
dd-LocalGroupMember -Group "Users" -Member "StudentLL"
