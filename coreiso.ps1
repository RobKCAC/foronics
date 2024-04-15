# PowerShell script to disable Core Isolation Memory Integrity in Windows 11 and confirm before restart

# Ensure you are running the script as an Administrator

# Disable Memory Integrity
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0
Write-Output "Core Isolation Disabled"
# Ask for confirmation before restarting
$confirmation = Read-Host "Do you want to restart the computer now? (Y/N)"
if ($confirmation -eq 'Y') {
    Restart-Computer
} else {
    
    Write-Host "The computer will not restart now. Please restart manually for the changes to take effect."
}
