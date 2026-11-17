# Paso 5b - Comprobar en el cliente que las GPO se aplican (ejecutar con un usuario del dominio)
"Usuario: $(whoami)   Equipo: $env:COMPUTERNAME   Dominio: $env:USERDNSDOMAIN"
gpupdate /target:user /force | Out-Null

'--- GPO aplicadas al usuario ---'
gpresult /r /scope user | Select-String -Context 0, 6 'Applied Group Policy Objects'

'--- Fondo corporativo ---'
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction SilentlyContinue |
    Format-List Wallpaper, WallpaperStyle

'--- Panel de control bloqueado (1 = bloqueado, vacio = permitido) ---'
(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -ErrorAction SilentlyContinue).NoControlPanel

'--- Unidad S: ---'
Get-PSDrive S -ErrorAction SilentlyContinue | Format-Table Name, DisplayRoot
net use
