<#
  Restablece la contrasena de un usuario o genera su enlace de restablecimiento,
  usando la API de Admin de Firebase (Identity Toolkit) y el token de la CLI
  (guardado en %USERPROFILE%\.config\configstore\firebase-tools.json).

  No requiere el Firebase CLI. El enlace funciona aunque el correo del usuario no
  exista (se genera con `returnOobLink`).

  Uso (desde la raiz del repositorio):
    # Genera el enlace de restablecimiento
    powershell -File .opencode/skills/restablecer-clave/scripts/restablecer-clave.ps1 -Correo usuario@correo.com

    # Fija directamente una contrasena (para pruebas)
    powershell -File .opencode/skills/restablecer-clave/scripts/restablecer-clave.ps1 -Correo usuario@correo.com -Clave 123456
    powershell -File .opencode/skills/restablecer-clave/scripts/restablecer-clave.ps1 -Uid <uid> -Clave 123456
#>
param(
  [string]$Correo = '',
  [string]$Uid = '',
  [string]$Clave = ''
)

$ErrorActionPreference = 'Stop'
$proj = 'aplicativo-de-ventas-d8bcd'

$configPath = Join-Path $env:USERPROFILE '.config\configstore\firebase-tools.json'
$refresh = (Get-Content $configPath -Raw | ConvertFrom-Json).tokens.refresh_token

# client_id/secret publicos de firebase-tools (no son secretos).
$body = @{
  client_id     = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com'
  client_secret = 'j9iVZfS8kkCEFUPaAeJV0sAi'
  refresh_token = $refresh
  grant_type    = 'refresh_token'
}
$tok = (Invoke-RestMethod -Method Post -Uri 'https://oauth2.googleapis.com/token' -Body $body).access_token
$h = @{ Authorization = "Bearer $tok"; 'Content-Type' = 'application/json' }

# Resuelve el uid a partir del correo, si no se dio.
if (-not $Uid -and $Correo) {
  $lookup = @{ email = @($Correo) } | ConvertTo-Json -Compress
  $r = Invoke-RestMethod -Method Post `
    -Uri "https://identitytoolkit.googleapis.com/v1/projects/$proj/accounts:lookup" `
    -Headers $h -Body $lookup
  if ($r.users -and $r.users.Count -gt 0) { $Uid = $r.users[0].localId }
}

if ($Clave) {
  if (-not $Uid) { throw 'Indica -Uid o -Correo para fijar la contrasena.' }
  $b = @{ localId = $Uid; password = $Clave } | ConvertTo-Json -Compress
  $r = Invoke-RestMethod -Method Post `
    -Uri "https://identitytoolkit.googleapis.com/v1/projects/$proj/accounts:update" `
    -Headers $h -Body $b
  Write-Output "Contrasena actualizada para $($r.email) (uid $($r.localId))."
} else {
  if (-not $Correo) { throw 'Indica -Correo para generar el enlace.' }
  $b = @{
    requestType  = 'PASSWORD_RESET'
    email        = $Correo
    returnOobLink = $true
  } | ConvertTo-Json -Compress
  $r = Invoke-RestMethod -Method Post `
    -Uri "https://identitytoolkit.googleapis.com/v1/projects/$proj/accounts:sendOobCode" `
    -Headers $h -Body $b
  Write-Output "Enlace de restablecimiento para $($r.email):"
  Write-Output $r.oobLink
}
