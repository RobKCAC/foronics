<#
.SYNOPSIS
    (ADMIN ONLY) Removes stored credentials from ALL user profiles on a local machine.

.DESCRIPTION
    This script is for administrators. It forcefully removes all cached credentials from the
    Windows Credential Manager by deleting the credential files from every user's profile
    folder found on the system. This is useful for cleaning a shared computer or terminal server.

.NOTES
    - MUST be run as an Administrator.
    - It is recommended to run this when users are logged off the machine.
    - This action is destructive and cannot be undone.

.EXAMPLE
    .\Clear-AllUserCredentials.ps1 -WhatIf
    Performs a "dry run" showing which user profiles and credential files would be targeted
    for deletion without actually removing anything. THIS IS HIGHLY RECOMMENDED.

.EXAMPLE
    .\Clear-AllUserCredentials.ps1
    Executes the deletion for all user profiles after a confirmation prompt.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param ()

#region --- Pre-flight Checks ---
# Check for Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run with Administrator privileges. Please re-launch PowerShell as an Administrator."
    return
}

Write-Host "INFO: Running with Administrator privileges." -ForegroundColor Green
#endregion

#region --- Main Logic ---
# Get all user profiles on the machine, excluding system-managed ones.
# Win32_UserProfile is more reliable than just listing C:\Users folders.
$ErrorActionPreference = 'SilentlyContinue'
$UserProfiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.Special -eq $false -and $_.LocalPath -notlike "*\Default" -and $_.LocalPath -notlike "*\Public" }
$ErrorActionPreference = 'Continue'

if (-not $UserProfiles) {
    Write-Warning "Could not find any user profiles to process."
    return
}

Write-Host "INFO: Found $($UserProfiles.Count) user profiles to process." -ForegroundColor Cyan

foreach ($Profile in $UserProfiles) {
    $UserName = $Profile.LocalPath.Split('\')[-1]
    Write-Host "`n--- Processing profile for user: $UserName ---" -ForegroundColor Yellow
    
    # Define the two primary locations for credential files
    $CredentialFolders = @(
        Join-Path -Path $Profile.LocalPath -ChildPath "AppData\Local\Microsoft\Credentials"
        Join-Path -Path $Profile.LocalPath -ChildPath "AppData\Roaming\Microsoft\Credentials"
    )

    foreach ($Folder in $CredentialFolders) {
        if (Test-Path -Path $Folder) {
            # Get all the credential files within the folder
            $CredentialFiles = Get-ChildItem -Path $Folder -File -Recurse

            if ($CredentialFiles) {
                # Use ShouldProcess to enable -WhatIf and -Confirm
                if ($PSCmdlet.ShouldProcess("All files in '$Folder'", "Delete Credentials for user '$UserName'")) {
                    try {
                        Remove-Item -Path "$Folder\*" -Force -Recurse -ErrorAction Stop
                        Write-Host "SUCCESS: Cleared credentials from '$Folder'." -ForegroundColor Green
                    }
                    catch {
                        Write-Warning "Could not clear credentials from '$Folder'. The folder or files may be in use by a logged-on user."
                    }
                }
            }
            else {
                Write-Host "INFO: Credential folder '$Folder' is empty. Nothing to do."
            }
        }
        else {
            Write-Host "INFO: Credential folder '$Folder' not found for user '$UserName'."
        }
    }
}

Write-Host "`nOperation complete." -ForegroundColor Cyan
#endregion
