# Verificacion rapida del controlador de dominio
Get-CimInstance Win32_ComputerSystem | Format-List Name, Domain, DomainRole   # DomainRole 5 = DC principal
Get-Service NTDS, DNS, Netlogon, ADWS, DHCPServer | Format-Table Name, Status -AutoSize
Get-ADDomain | Format-List DNSRoot, NetBIOSName, PDCEmulator, DomainMode
Resolve-DnsName dailybrew.local -Type A | Format-Table Name, IPAddress
Resolve-DnsName _ldap._tcp.dc._msdcs.dailybrew.local -Type SRV | Format-Table Name, NameTarget, Port
