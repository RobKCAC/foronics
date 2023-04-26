# Dell Command | Update must run in an elevated mode. As a consequence this script must be run in an elevated PowerShell session.

md C:\ITS\Hidden\FScripts
md C:\ITS\Logs

$DriveRoot = $env:SystemDrive
$ScriptPath = "ITS\Hidden\FScripts"
$LogDirectory = (Join-Path -Path $DriveRoot -ChildPath $ScriptPath)
$LogFile = "FScripts_Log.txt"
$LogDate = (Get-Date).ToString("yyyy-MM-dd hh:mm:ss")
$Tab = "`t"

$LogMessage = "Starting the 'Get-DCU_Updates' script"
($LogDate + $Tab + $LogMessage) | Out-File -FilePath (Join-Path -Path $LogDirectory -ChildPath $LogFile) -Append

###### Dell Command | Update - Universal (x64) ######
$ProgramPath = "Program Files\Dell\CommandUpdate"
$WorkingDirectory = (Join-Path -Path $DriveRoot -ChildPath $ProgramPath)
$ExecutableFile = "dcu-cli.exe"
$ExecutablePath = Join-Path -Path $WorkingDirectory -ChildPath $ExecutableFile

$DCU_Found = Test-Path 'C:\Program Files\Dell\CommandUpdate\dcu-cli.exe'

$ArgumentList = "/applyUpdates","-silent","-reboot=disable","-outputLog=C:\ITS\Logs\DCU_Output.log"

If ($DCU_Found) {
    $LogDate = (Get-Date).ToString("yyyy-MM-dd hh:mm:ss")
    $LogMessage = "Running Dell Command | Update (x64), results will get saved in C:\ITS\Logs\DCU_Output.log"
    ($LogDate + $Tab + $LogMessage) | Out-File -FilePath (Join-Path -Path $LogDirectory -ChildPath $LogFile) -Append
    Start-Process -FilePath $ExecutablePath -ArgumentList $ArgumentList -WorkingDirectory $WorkingDirectory -Wait
}
Else {
    $LogDate = (Get-Date).ToString("yyyy-MM-dd hh:mm:ss")
    $LogMessage = "CANNOT run Dell Command | Update (x64), the executable file is not found."
    ($LogDate + $Tab + $LogMessage) | Out-File -FilePath (Join-Path -Path $LogDirectory -ChildPath $LogFile) -Append

}

######

###### Dell Command | Update - Standard (x86) ######
$ProgramPath = "Program Files (x86)\Dell\CommandUpdate"
$WorkingDirectory = (Join-Path -Path $DriveRoot -ChildPath $ProgramPath)
$ExecutableFile = "dcu-cli.exe"
$ExecutablePath = Join-Path -Path $WorkingDirectory -ChildPath $ExecutableFile

$DCU_Found = Test-Path 'C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe'

$ArgumentList = "/applyUpdates","-silent","-reboot=disable","-outputLog=C:\ITS\Logs\DCU_x86_Output.log"

If ($DCU_Found) {
    $LogDate = (Get-Date).ToString("yyyy-MM-dd hh:mm:ss")
    $LogMessage = "Running Dell Command | Update (x86), results will get saved in C:\ITS\Logs\DCU_x86_Output.log"
    ($LogDate + $Tab + $LogMessage) | Out-File -FilePath (Join-Path -Path $LogDirectory -ChildPath $LogFile) -Append
    Start-Process -FilePath $ExecutablePath -ArgumentList $ArgumentList -WorkingDirectory $WorkingDirectory -Wait
}
Else {
    $LogDate = (Get-Date).ToString("yyyy-MM-dd hh:mm:ss")
    $LogMessage = "CANNOT run Dell Command | Update (x86), the executable file is not found."
    ($LogDate + $Tab + $LogMessage) | Out-File -FilePath (Join-Path -Path $LogDirectory -ChildPath $LogFile) -Append

}

######

$LogDate = (Get-Date).ToString("yyyy-MM-dd hh:mm:ss")
$LogMessage = "Finished the Get-DCU_Updates script"
($LogDate + $Tab + $LogMessage) | Out-File -FilePath (Join-Path -Path $LogDirectory -ChildPath $LogFile) -Append
