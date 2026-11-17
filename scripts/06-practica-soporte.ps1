# Paso 6 - Tareas diarias de soporte: resetear clave, desbloquear cuenta, mover de grupo
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory
$raiz = 'OU=DailyBrew,DC=dailybrew,DC=local'

# Politica de bloqueo: 3 intentos fallidos bloquean la cuenta 30 minutos
Set-ADDefaultDomainPasswordPolicy -Identity dailybrew.local -LockoutThreshold 3 `
    -LockoutDuration 00:30:00 -LockoutObservationWindow 00:30:00

'=== 1. RESETEAR CONTRASENA (alopez olvido su clave) ==='
$nueva = Read-Host 'Nueva contrasena temporal para alopez' -AsSecureString
Set-ADAccountPassword -Identity alopez -Reset -NewPassword $nueva
Set-ADUser -Identity alopez -ChangePasswordAtLogon $true      # debe cambiarla al entrar
Get-ADUser alopez -Properties PasswordLastSet, pwdLastSet |
    Format-List SamAccountName, PasswordLastSet, @{n='DebeCambiarClave'; e={ $_.pwdLastSet -eq 0 }}

'=== 2. DESBLOQUEAR CUENTA (jhernandez fallo la clave 3 veces) ==='
1..4 | ForEach-Object {
    try {
        $e = New-Object DirectoryServices.DirectoryEntry('LDAP://dc01.dailybrew.local', 'DAILYBREW\jhernandez', 'ClaveMala!')
        $null = $e.NativeObject
    } catch { }
}
Start-Sleep 2
'Antes:   LockedOut = ' + (Get-ADUser jhernandez -Properties LockedOut).LockedOut
Search-ADAccount -LockedOut | Format-Table SamAccountName, LockedOut, LastLogonDate
Unlock-ADAccount -Identity jhernandez
'Despues: LockedOut = ' + (Get-ADUser jhernandez -Properties LockedOut).LockedOut

'=== 3. MOVER DE GRUPO (dcastillo pasa de Ventas a Administracion) ==='
'Antes:   ' + ((Get-ADPrincipalGroupMembership dcastillo).Name -join ', ')
Remove-ADGroupMember -Identity GG_Ventas -Members dcastillo -Confirm:$false
Add-ADGroupMember    -Identity GG_Administracion -Members dcastillo
Get-ADUser dcastillo | Move-ADObject -TargetPath "OU=Administracion,$raiz"
Set-ADUser dcastillo -Department 'Administracion'
'Despues: ' + ((Get-ADPrincipalGroupMembership dcastillo).Name -join ', ')
'Nueva ubicacion: ' + (Get-ADUser dcastillo).DistinguishedName
