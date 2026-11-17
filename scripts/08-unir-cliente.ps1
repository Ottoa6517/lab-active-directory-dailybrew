# Paso 4 - Unir el cliente Windows 10 al dominio (ejecutar en CLIENTE01 como administrador local)
$ErrorActionPreference = 'Stop'

# El cliente debe haber recibido IP y DNS del DHCP del servidor
ipconfig /renew | Out-Null
Get-NetIPConfiguration | Format-List InterfaceAlias, IPv4Address, DNSServer
Resolve-DnsName dailybrew.local | Format-Table Name, IPAddress
Test-Connection dc01.dailybrew.local -Count 2 | Format-Table Address, IPV4Address, ResponseTime

$cred  = Get-Credential -UserName 'DAILYBREW\Administrator' -Message 'Cuenta con permiso para unir equipos al dominio'
Add-Computer -DomainName 'dailybrew.local' -Credential $cred `
    -OUPath 'OU=Equipos,OU=DailyBrew,DC=dailybrew,DC=local' -Force
'Equipo unido al dominio. Reiniciando...'
Restart-Computer -Force
