New-LocalUser -Name sign -NoPassword -UserMayNotChangePassword
Set-LocalUser -Name sign -PasswordNeverExpires $true
Add-LocalGroupMember -Group "Administrators" -Member "sign"
