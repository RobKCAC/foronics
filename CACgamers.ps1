New-LocalUser -Name CAC_Gamers -NoPassword -UserMayNotChangePassword
Set-LocalUser -Name CAC_Gamers -PasswordNeverExpires $true
Add-LocalGroupMember -Group "Users" -Member "CAC_Gamers"
