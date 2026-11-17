# Paso 2c - Autorizar DHCP en el dominio y crear el ambito de la red interna
$ErrorActionPreference = 'Stop'

Add-DhcpServerInDC -DnsName 'dc01.dailybrew.local' -IPAddress 192.168.10.10
# Quita el aviso de "configuracion pendiente" del Server Manager
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12' -Name ConfigurationState -Value 2

if (-not (Get-DhcpServerv4Scope -ScopeId 192.168.10.0 -ErrorAction SilentlyContinue)) {
    Add-DhcpServerv4Scope -Name 'DailyBrew-LAN' -StartRange 192.168.10.100 -EndRange 192.168.10.200 `
        -SubnetMask 255.255.255.0 -State Active
}
Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -DnsServer 192.168.10.10 -DnsDomain 'dailybrew.local'
Restart-Service DHCPServer

Get-DhcpServerInDC | Format-Table
Get-DhcpServerv4Scope | Format-Table ScopeId, Name, StartRange, EndRange, State
