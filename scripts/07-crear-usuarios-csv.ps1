<#
.SYNOPSIS
    Crea usuarios de Active Directory en masa desde un archivo CSV.
.DESCRIPTION
    Columnas del CSV: Nombre, Apellido, Usuario, Departamento
    El departamento debe ser una OU existente bajo OU=DailyBrew (Ventas, Cocina, Administracion).
    Cada usuario se crea en su OU, se agrega al grupo GG_<Departamento> y debe cambiar
    la contrasena en el primer inicio de sesion. Los usuarios que ya existen se omiten.
.EXAMPLE
    .\07-crear-usuarios-csv.ps1 -CsvPath .\usuarios.csv
.EXAMPLE
    .\07-crear-usuarios-csv.ps1 -CsvPath .\usuarios.csv -WhatIf     # simula sin crear nada
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [Parameter(Mandatory)][securestring]$ClaveInicial,
    [string]$Dominio = 'dailybrew.local',
    [string]$OuRaiz = 'OU=DailyBrew,DC=dailybrew,DC=local'
)
Import-Module ActiveDirectory
if (-not (Test-Path $CsvPath)) { throw "No existe el archivo $CsvPath" }

$clave = $ClaveInicial
$resultado = foreach ($fila in Import-Csv $CsvPath) {
    $usuario = $fila.Usuario.Trim().ToLower()
    $estado  = 'Creado'
    try {
        if (-not $usuario -or -not $fila.Nombre -or -not $fila.Apellido) { throw 'Fila incompleta' }
        $ou = "OU=$($fila.Departamento.Trim()),$OuRaiz"
        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ou'")) {
            throw "No existe la OU $($fila.Departamento)"
        }
        if (Get-ADUser -Filter "SamAccountName -eq '$usuario'") {
            $estado = 'Omitido (ya existe)'
        }
        elseif ($PSCmdlet.ShouldProcess($usuario, 'Crear usuario')) {
            New-ADUser -Name "$($fila.Nombre) $($fila.Apellido)" -GivenName $fila.Nombre -Surname $fila.Apellido `
                -SamAccountName $usuario -UserPrincipalName "$usuario@$Dominio" `
                -Department $fila.Departamento -Path $ou -AccountPassword $clave `
                -ChangePasswordAtLogon $true -Enabled $true -ErrorAction Stop
            Add-ADGroupMember -Identity "GG_$($fila.Departamento.Trim())" -Members $usuario -ErrorAction Stop
        }
        else { $estado = 'Simulado' }
    }
    catch { $estado = "ERROR: $($_.Exception.Message)" }
    [pscustomobject]@{ Usuario = $usuario; Departamento = $fila.Departamento; Estado = $estado }
}

$resultado | Format-Table -AutoSize
"Creados: {0} | Omitidos: {1} | Errores: {2}" -f `
    @($resultado | Where-Object Estado -eq 'Creado').Count,
    @($resultado | Where-Object Estado -like 'Omitido*').Count,
    @($resultado | Where-Object Estado -like 'ERROR*').Count
