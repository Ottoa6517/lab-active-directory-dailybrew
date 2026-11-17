# Paso 5 - Carpeta compartida y 3 politicas de grupo (GPO)
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory, GroupPolicy
$dom  = 'DC=dailybrew,DC=local'
$raiz = "OU=DailyBrew,$dom"

# --- Carpeta compartida ---
$carpeta = 'C:\Compartido'
New-Item -ItemType Directory -Force $carpeta | Out-Null
Set-Content "$carpeta\LEEME.txt" 'Carpeta compartida de Daily Brew. Se mapea sola como unidad S: por GPO.'
if (-not (Get-SmbShare -Name Compartido -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name Compartido -Path $carpeta -ChangeAccess 'DAILYBREW\Domain Users' -FullAccess 'DAILYBREW\Domain Admins' | Out-Null
}
icacls $carpeta /grant 'DAILYBREW\Domain Users:(OI)(CI)M' | Out-Null

# --- Imagen del fondo corporativo, publicada en NETLOGON ---
Add-Type -AssemblyName System.Drawing
$img = "C:\Windows\SYSVOL\domain\scripts\dailybrew-fondo.jpg"
$bmp = New-Object Drawing.Bitmap 1920, 1080
$g   = [Drawing.Graphics]::FromImage($bmp)
$g.Clear([Drawing.Color]::FromArgb(59, 36, 23))
$f1 = New-Object Drawing.Font 'Segoe UI', 96, ([Drawing.FontStyle]::Bold)
$f2 = New-Object Drawing.Font 'Segoe UI', 28
$fmt = New-Object Drawing.StringFormat
$fmt.Alignment = 'Center'
$g.DrawString('DAILY BREW', $f1, [Drawing.Brushes]::Wheat, 960, 400, $fmt)
$g.DrawString('Equipo corporativo - dailybrew.local', $f2, [Drawing.Brushes]::BurlyWood, 960, 580, $fmt)
$bmp.Save($img, [Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose(); $bmp.Dispose()

# --- GPO 1: fondo de pantalla corporativo (toda la empresa) ---
$n1 = 'DB - Fondo corporativo'
if (-not (Get-GPO -Name $n1 -ErrorAction SilentlyContinue)) { New-GPO -Name $n1 | Out-Null }
$k = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System'
Set-GPRegistryValue -Name $n1 -Key $k -ValueName Wallpaper -Type String -Value '\\dailybrew.local\NETLOGON\dailybrew-fondo.jpg' | Out-Null
Set-GPRegistryValue -Name $n1 -Key $k -ValueName WallpaperStyle -Type String -Value '2' | Out-Null
New-GPLink -Name $n1 -Target $raiz -ErrorAction SilentlyContinue | Out-Null

# --- GPO 2: bloquear el Panel de control solo a Ventas ---
$n2 = 'DB - Ventas sin Panel de control'
if (-not (Get-GPO -Name $n2 -ErrorAction SilentlyContinue)) { New-GPO -Name $n2 | Out-Null }
Set-GPRegistryValue -Name $n2 -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' `
    -ValueName NoControlPanel -Type DWord -Value 1 | Out-Null
New-GPLink -Name $n2 -Target "OU=Ventas,$raiz" -ErrorAction SilentlyContinue | Out-Null

# --- GPO 3: unidad S: mapeada sola (Preferencias > Asignaciones de unidades) ---
$n3 = 'DB - Unidad S compartida'
$gpo = Get-GPO -Name $n3 -ErrorAction SilentlyContinue
if (-not $gpo) { $gpo = New-GPO -Name $n3 }
$id   = "{$($gpo.Id)}"
$base = "C:\Windows\SYSVOL\domain\Policies\$id"
$dir  = "$base\User\Preferences\Drives"
New-Item -ItemType Directory -Force $dir | Out-Null
$uid = "{$([guid]::NewGuid().ToString().ToUpper())}"
$fecha = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
@"
<?xml version="1.0" encoding="utf-8"?>
<Drives clsid="{8FDDCC1A-0C3C-43cd-A6B4-71A6DF20DA8C}"><Drive clsid="{935D1B74-9CB8-4e3c-9914-7DD559B7A417}" name="S:" status="S:" image="2" changed="$fecha" uid="$uid" bypassErrors="1"><Properties action="U" thisDrive="NOCHANGE" allDrives="NOCHANGE" userName="" path="\\dc01.dailybrew.local\Compartido" label="DailyBrew" persistent="1" useLetter="1" letter="S"/></Drive></Drives>
"@ | Set-Content "$dir\Drives.xml" -Encoding UTF8
# Una GPO solo aplica Preferencias si declara la extension y sube su numero de version
$ext = '[{00000000-0000-0000-0000-000000000000}{2EA1A81B-48E5-45E9-8BB7-A6E3AC170006}][{5794DAFD-BE60-433F-88A2-1A31939AC01F}{2EA1A81B-48E5-45E9-8BB7-A6E3AC170006}]'
$dn  = "CN=$id,CN=Policies,CN=System,$dom"
$ver = [int](Get-ADObject $dn -Properties versionNumber).versionNumber + 65536
Set-ADObject $dn -Replace @{ gPCUserExtensionNames = $ext; versionNumber = $ver }
Set-Content "$base\GPT.INI" "[General]`r`nVersion=$ver`r`n" -Encoding ASCII
New-GPLink -Name $n3 -Target $raiz -ErrorAction SilentlyContinue | Out-Null

Get-GPO -All | Where-Object DisplayName -like 'DB -*' | Format-Table DisplayName, GpoStatus, Id
(Get-GPInheritance -Target "OU=Ventas,$raiz").InheritedGpoLinks | Format-Table DisplayName, Target, Enabled
