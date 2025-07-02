<#
.SYNOPSIS
    Removes all stored credentials from the current user's Windows Credential Manager.

.DESCRIPTION
    This script identifies and deletes all credentials stored in the Windows Vault
    (Credential Manager) for the user account executing the script. This is useful for
    clearing out old or incorrect passwords that may be causing account lockouts.
    The script uses the native 'cmdkey.exe' utility.

.PARAMETER WhatIf
    Shows the credentials that would be deleted without actually deleting them.

.PARAMETER Confirm
    Prompts the user for confirmation before deleting each credential.

.EXAMPLE
    .\Clear-CachedCredentials.ps1
    This will run the script and delete all credentials after a single confirmation prompt.

.EXAMPLE
    .\Clear-CachedCredentials.ps1 -WhatIf
    This will perform a "dry run", showing you every credential that would be removed.

.EXAMPLE
    .\Clear-CachedCredentials.ps1 -Confirm
    This will prompt you to confirm the deletion of each individual credential.

.NOTES
    Author: Gemini from Google
    This script must be run by the user whose credentials you wish to clear,
    or via a tool that can execute commands in another user's context (like PsExec).
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param ()

Write-Host "INFO: Searching for stored credentials for the current user ($env:USERNAME)..." -ForegroundColor Cyan

# Get the raw output from cmdkey.exe
$CmdKeyOutput = cmdkey /list

# Find lines containing "Target:" and extract the target name for each
$CredentialTargets = $CmdKeyOutput | ForEach-Object {
    if ($_ -match '^\s*Target:\s*(.+)') {
        $matches[1]
    }
}

if (-not $CredentialTargets) {
    Write-Host "SUCCESS: No stored credentials found in the Windows Credential Manager for this user." -ForegroundColor Green
    return
}

Write-Host "INFO: Found $($CredentialTargets.Count) credentials to remove." -ForegroundColor Yellow

foreach ($Target in $CredentialTargets) {
    # The $PSCmdlet.ShouldProcess() enables -WhatIf and -Confirm functionality
    if ($PSCmdlet.ShouldProcess($Target, "Delete Credential")) {
        try {
            cmdkey /delete:$Target
            Write-Host "DELETED: $Target" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to delete credential: $Target"
        }
    }
}

Write-Host "---"
Write-Host "Operation complete." -ForegroundColor Cyan
