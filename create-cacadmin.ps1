$Password = Read-Host -AsSecureString
$params = @{
    Name        = 'CACadmin'
    Password    = $Password
    FullName    = 'CACadmin'
    Description = 'Laps Admin'
}
New-LocalUser @params
Add-LocalGroupMember -Group "Administrators" -Member "CACadmin"
