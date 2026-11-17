# Paso 2a - IP fija e instalacion de roles (ejecutar en DC01 como Administrator)
$ErrorActionPreference = 'Stop'

# IP fija en el adaptador de la red interna
$nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
Get-NetIPAddress -InterfaceIndex $nic.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
New-NetIPAddress -InterfaceIndex $nic.ifIndex -IPAddress 192.168.10.10 -PrefixLength 24 | Out-Null
Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses 127.0.0.1

# Roles: Active Directory Domain Services, DNS y DHCP
Install-WindowsFeature AD-Domain-Services, DNS, DHCP -IncludeManagementTools

Get-NetIPAddress -InterfaceIndex $nic.ifIndex -AddressFamily IPv4 | Format-Table IPAddress, PrefixLength
Get-WindowsFeature AD-Domain-Services, DNS, DHCP | Format-Table Name, InstallState
