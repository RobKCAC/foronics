Set-Service -Name UsoSvc -StartupType Automatic
Set-Service -Name wuauserv -StartupType Automatic
Set-Service -Name UsoSvc -Status Running
Set-Service -Name wuauserv -Status Running
Get-AppxPackage "AppInstaller" | add-appxpackage
winget install -q Microsoft.Office  --accept-source-agreements
