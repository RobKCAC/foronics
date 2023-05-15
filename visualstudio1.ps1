Set-Service -Name UsoSvc -StartupType Automatic
Set-Service -Name wuauserv -StartupType Automatic
Set-Service -Name UsoSvc -Status Running
Set-Service -Name wuauserv -Status Running
Get-AppxPackage "AppInstaller" | add-appxpackage
Add-Path "c:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_1.18.431.0_x64__8wekyb3d8bbwe"
winget.exe source reset --force
winget.exe source update --silent --accept-package-agreements --accept-source-agreements --exact --scope machine
winget.exe install Microsoft.VisualStudio.2022.Community --silent --accept-package-agreements --accept-source-agreements --exact --scope machine
