# Enable RPC Server and supporting services
# Save as Enable-RPC-Full.ps1

# 1️⃣ Ensure Remote Procedure Call (RPC) is Automatic and Running
Set-Service -Name RpcSs -StartupType Automatic
Start-Service -Name RpcSs

# 2️⃣ Ensure DCOM Server Process Launcher is Automatic and Running
Set-Service -Name DcomLaunch -StartupType Automatic
Start-Service -Name DcomLaunch

# 3️⃣ Ensure RPC Endpoint Mapper is Automatic and Running
Set-Service -Name RpcEptMapper -StartupType Automatic
Start-Service -Name RpcEptMapper

# 4️⃣ Enable Remote Registry Service (Optional)
Set-Service -Name RemoteRegistry -StartupType Automatic
Start-Service -Name RemoteRegistry

# 5️⃣ Enable Firewall Rules for RPC
# Enable predefined Windows Firewall rules
# These rules allow inbound RPC-EPM and DCOM traffic

# Enable RPC-EPM
Enable-NetFirewallRule -DisplayGroup "Remote Event Log Management"
Enable-NetFirewallRule -DisplayGroup "Remote Service Management"
Enable-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)"
Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing"

# Optionally, confirm all rules enabled
Write-Host "Firewall rules for RPC, WMI, and Remote Management enabled."

# 6️⃣ Confirm service status
Get-Service -Name RpcSs, DcomLaunch, RpcEptMapper, RemoteRegistry | Select-Object DisplayName, Status, StartType

Write-Host "✅ RPC and supporting services are enabled and running."
