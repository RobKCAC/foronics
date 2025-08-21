# PowerShell Script to Set DNS Server on All Network Adapters
# Run as Administrator

# Define your preferred DNS servers
$dnsServers = "10.10.2.22","10.10.2.23"   # Firepower

# Get all physical/adapters that are up
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($adapter in $adapters) {
    Write-Host "Setting DNS for adapter: $($adapter.Name)"
    
    # Clear existing DNS servers
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses
    
    # Apply new DNS servers
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dnsServers
}

Write-Host "DNS servers set to $($dnsServers -join ', ') on all active adapters."

