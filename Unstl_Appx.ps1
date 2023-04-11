Enable-PSRemoting -Force -SkipNetworkProfileCheck

#https://social.technet.microsoft.com/Forums/en-US/9cb41ec6-a7a5-46b0-838c-dce2dce2fd83/problem-with-removeappxprovisionedpackage-on-a-fresh-install-of-windows-10-enterprise-build-1803?forum=win10itprosetup

 Write-Host "Removing Apps..." -ForegroundColor Green
    Write-Host ""
    
    # Create array to hold list of apps to remove
    $appname = @(
        "*Microsoft.BingNews*"
        "*Microsoft.BingWeather*"
#        "*Microsoft.DesktopAppInstaller*"
        "*Microsoft.GetHelp*"                          
        "*Microsoft.Getstarted*"
        "*Microsoft.LanguageExperiencePacken-gb*"
        "*Microsoft.Messaging*"
        "*Microsoft.MicrosoftOfficeHub*"
        "*Microsoft.MixedReality.Portal*"
#        "*Microsoft.MSPaint*"
        "*Microsoft.Office.OneNote*"
        "*Microsoft.OneConnect*"
        "*Microsoft.People*"                           
        "*Microsoft.Skype*"
#        "*Microsoft.StorePurchaseApp*"                 
        "*microsoft.windowscommunicationsapps*"
        "*Microsoft.WindowsFeedbackHub*"
        "*Microsoft.WindowsMaps*"
#        "*Microsoft.WindowsStore*"                     
        "*Microsoft.Xbox.TCUI*" 
        "*Microsoft.XboxApp*" 
        "*Microsoft.XboxGameOverlay*" 
        "*Microsoft.XboxGamingOverlay*" 
        "*Microsoft.XboxIdentityProvider*" 
        "*Microsoft.XboxSpeechToTextOverlay*" 
        "*Microsoft.YourPhone*"
                #"*Windows.CBSPreview*"
    )

    # Remove apps from current user
    ForEach($app in $appname){
    Get-AppxPackage -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
    }

    # Remove apps from all users - may need to reboot after running above and run this again
    ForEach($app in $appname){
    Get-AppxPackage -Allusers -Name $app | Remove-AppxPackage -Allusers -ErrorAction SilentlyContinue
    }

    # Remove apps from provisioned apps list so they don't reinstall on new users
    ForEach($app in $appname){
    Get-AppxProvisionedPackage -Online | where {$_.PackageName -like $app} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }

Get-AppxProvisionedPackage -Online | Select PackageName | sort
Start-Sleep -Seconds 120

