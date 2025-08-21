# Define primary and secondary DNS server addresses
$dnsServers = @("10.10.2.22", "10.10.22.23")  # cac Firepower

# Get all network adapters, including disconnected and virtual ones
$adapters = Get-NetAdapter

foreach ($adapter in $adapters) {
    $interfaceAlias = $adapter.Name
    Write-Host "Setting DNS for adapter: $interfaceAlias"

    try {
        # Apply DNS server settings
        Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses $dnsServers
        Write-Host "Successfully set DNS for $interfaceAlias"
    } catch {
        Write-Warning "Failed to set DNS for $interfaceAlias: $_"
    }
}
