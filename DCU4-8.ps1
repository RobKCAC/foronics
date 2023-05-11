Set-Service -Name UsoSvc -StartupType Automatic
Set-Service -Name wuauserv -StartupType Automatic
Set-Service -Name UsoSvc -Status Running
Set-Service -Name wuauserv -Status Running
winget source update
winget install  Dell.CommandUpdate.Universal --silent --accept-package-agreements --accept-source-agreements
