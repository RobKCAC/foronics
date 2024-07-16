New-LocalUser -Name AdultED -NoPassword -UserMayNotChangePassword
Set-LocalUser -Name AdultED -PasswordNeverExpires $true
Add-LocalGroupMember -Group "Users" -Member "AdultED"
