Set-Service -Name UsoSvc -StartupType Automatic
Set-Service -Name wuauserv -StartupType Automatic
Set-Service -Name UsoSvc -Status Running
Set-Service -Name wuauserv -Status Running
Get-AppxPackage "AppInstaller" | add-appxpackage
c:
cd \
cd "\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_1.18.431.0_x64__8wekyb3d8bbwe"
winget.exe source update
winget.exe install Microsoft.VisualStudio.2022.Community --silent --accept-package-agreements --accept-source-agreements
