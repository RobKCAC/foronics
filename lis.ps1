$Name = @{
    Namespace = 'root\cimv2\power'
}
$ID = (Get-WmiObject @Name Win32_PowerPlan -Filter "IsActive = TRUE") -replace '.*(\{.*})"', '$1'
$Lid = '{5ca83367-6e45-459f-a27b-476b1d01c936}'
Get-WmiObject @Name Win32_PowerSettingDataIndex -Filter "InstanceId LIKE '%$Id\\%C\\$Lid'" | 
    Set-WmiInstance -Arguments @{ SettingIndexValue = 0 }
