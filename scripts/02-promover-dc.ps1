# Paso 2b - Promover el servidor a controlador de dominio de un bosque nuevo
# El servidor se reinicia solo al terminar.
$ErrorActionPreference = 'Stop'
$dsrm = Read-Host 'Contrasena del modo de restauracion (DSRM)' -AsSecureString

Import-Module ADDSDeployment
Install-ADDSForest `
    -DomainName 'dailybrew.local' `
    -DomainNetbiosName 'DAILYBREW' `
    -SafeModeAdministratorPassword $dsrm `
    -InstallDns `
    -Force
