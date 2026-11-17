# Paso 3 - Unidades organizativas, 3 grupos y 10 usuarios
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory
$dom  = 'DC=dailybrew,DC=local'
$raiz = "OU=DailyBrew,$dom"
$pass = Read-Host 'Contrasena inicial para los usuarios' -AsSecureString

if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'DailyBrew'" -SearchBase $dom -SearchScope OneLevel)) {
    New-ADOrganizationalUnit -Name 'DailyBrew' -Path $dom
}
foreach ($ou in 'Ventas','Cocina','Administracion','Equipos') {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" -SearchBase $raiz -SearchScope OneLevel)) {
        New-ADOrganizationalUnit -Name $ou -Path $raiz
    }
}

foreach ($g in 'Ventas','Cocina','Administracion') {
    if (-not (Get-ADGroup -Filter "Name -eq 'GG_$g'")) {
        New-ADGroup -Name "GG_$g" -GroupScope Global -GroupCategory Security -Path "OU=$g,$raiz" `
            -Description "Personal de $g de Daily Brew"
    }
}

$usuarios = @(
    @{N='Ana';    A='Lopez';     U='alopez';     D='Ventas'},
    @{N='Carlos'; A='Mendez';    U='cmendez';    D='Ventas'},
    @{N='Lucia';  A='Ramirez';   U='lramirez';   D='Ventas'},
    @{N='Diego';  A='Castillo';  U='dcastillo';  D='Ventas'},
    @{N='Maria';  A='Garcia';    U='mgarcia';    D='Cocina'},
    @{N='Jose';   A='Hernandez'; U='jhernandez'; D='Cocina'},
    @{N='Sofia';  A='Perez';     U='sperez';     D='Cocina'},
    @{N='Pablo';  A='Morales';   U='pmorales';   D='Administracion'},
    @{N='Elena';  A='Ruiz';      U='eruiz';      D='Administracion'},
    @{N='Andres'; A='Soto';      U='asoto';      D='Administracion'}
)
foreach ($u in $usuarios) {
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.U)'")) {
        New-ADUser -Name "$($u.N) $($u.A)" -GivenName $u.N -Surname $u.A -SamAccountName $u.U `
            -UserPrincipalName "$($u.U)@dailybrew.local" -Department $u.D `
            -Path "OU=$($u.D),$raiz" -AccountPassword $pass -Enabled $true
    }
    Add-ADGroupMember -Identity "GG_$($u.D)" -Members $u.U -ErrorAction SilentlyContinue
}

Get-ADOrganizationalUnit -Filter * -SearchBase $raiz | Format-Table Name, DistinguishedName
Get-ADUser -Filter * -SearchBase $raiz -Properties Department | Sort-Object Department, SamAccountName |
    Format-Table SamAccountName, Name, Department, Enabled
foreach ($g in 'Ventas','Cocina','Administracion') {
    "GG_$g -> " + ((Get-ADGroupMember "GG_$g").SamAccountName -join ', ')
}
