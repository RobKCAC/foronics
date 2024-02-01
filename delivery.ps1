$RegistryPath =  'HKLM:\SYSTEM\CurrentControlSet\Services\DoSvc'
$Name = 'Start'
$Value = '4'

Set-ItemProperty -Path $RegistryPath -Name $Name -Value $Value
