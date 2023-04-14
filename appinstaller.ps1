Set-Service -Name UsoSvc -StartupType Automatic
Set-Service -Name wuauserv -StartupType Automatic
Set-Service -Name UsoSvc -Status Running
Set-Service -Name wuauservc -Status Running
Get-AppxPackage "AppInstaller" | add-appxpackage
