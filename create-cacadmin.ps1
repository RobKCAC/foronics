$Time = Get-Date -Format G
$Password = $Time+$env:COMPUTERNAME+'!'
$passwordConverted = ConvertTo-SecureString $password -AsPlainText -Force
$params = @{
    Name        = 'CACadmin'
    Password    = $passwordConverted
    FullName    = 'CACadmin'
    Description = 'Laps Admin'
}
New-LocalUser @params
Add-LocalGroupMember -Group "Administrators" -Member "CACadmin"
