# Path to the registry key
$registryPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"

# Create the registry key if it doesn't exist
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
}

# Set the IncognitoModeAvailability value to 1 (enabled)
Set-ItemProperty -Path $registryPath -Name "IncognitoModeAvailability" -Value 0
