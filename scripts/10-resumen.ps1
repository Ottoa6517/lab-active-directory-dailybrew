# Resumen del estado del laboratorio (para la captura del README)
Clear-Host
"== Servidor ==";  "$env:COMPUTERNAME.$env:USERDNSDOMAIN  |  IP: " + (Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -like '192.168.*').IPAddress
Get-ADDomain | Format-List DNSRoot, NetBIOSName, PDCEmulator
Get-Service NTDS, DNS, DHCPServer | Format-Table Name, Status -AutoSize
Get-DhcpServerv4Scope | Format-Table ScopeId, Name, StartRange, EndRange, State -AutoSize
"== Usuarios por grupo =="
foreach ($g in 'GG_Ventas', 'GG_Cocina', 'GG_Administracion') { "{0,-18} {1}" -f $g, ((Get-ADGroupMember $g).SamAccountName -join ', ') }
