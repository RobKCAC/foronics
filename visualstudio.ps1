Set-Service -Name UsoSvc -StartupType Automatic
Set-Service -Name wuauserv -StartupType Automatic
Set-Service -Name UsoSvc -Status Running
Set-Service -Name wuauserv -Status Running
Get-AppxPackage "AppInstaller" | add-appxpackage
winget source update
winget install Microsoft.VisualStudio.2022.Community --silent --accept-package-agreements --accept-source-agreements
