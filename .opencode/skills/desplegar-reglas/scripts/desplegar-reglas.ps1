<#
  Despliega reglas de Firebase (Firestore o Storage) usando la API de reglas,
  sin necesidad del Firebase CLI.

  Uso (desde la raíz del repositorio):
    powershell -File .opencode/skills/desplegar-reglas/scripts/desplegar-reglas.ps1 -Tipo firestore
    powershell -File .opencode/skills/desplegar-reglas/scripts/desplegar-reglas.ps1 -Tipo storage
#>
param(
  [ValidateSet('firestore', 'storage')]
  [string]$Tipo = 'firestore'
)

$ErrorActionPreference = 'Stop'
$proj = 'aplicativo-de-ventas-d8bcd'
$bucket = 'aplicativo-de-ventas-d8bcd.firebasestorage.app'

# refresh_token que guarda la CLI de Firebase (configstore).
$configPath = Join-Path $env:USERPROFILE '.config\configstore\firebase-tools.json'
$config = Get-Content $configPath -Raw | ConvertFrom-Json
$refresh = $config.tokens.refresh_token

# client_id/secret públicos de firebase-tools (no son secretos).
$body = @{
  client_id     = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com'
  client_secret = 'j9iVZfS8kkCEFUPaAeJV0sAi'
  refresh_token = $refresh
  grant_type    = 'refresh_token'
}
$tok = (Invoke-RestMethod -Method Post -Uri 'https://oauth2.googleapis.com/token' -Body $body).access_token

if ($Tipo -eq 'firestore') {
  $archivo = 'app/firestore.rules'
  $nombre = 'firestore.rules'
  $release = 'cloud.firestore'
} else {
  $archivo = 'app/storage.rules'
  $nombre = 'storage.rules'
  $release = "firebase.storage/$bucket"
}

# El contenido va envuelto en "source"; se envia como UTF-8 (acentos).
$content = Get-Content -Raw -Encoding UTF8 $archivo
$esc = $content.Replace('\', '\\').Replace('"', '\"').Replace("`r", '').Replace("`n", '\n')
$json = '{"source":{"files":[{"name":"' + $nombre + '","content":"' + $esc + '"}]}}'
$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

$r = Invoke-RestMethod -Method Post `
  -Uri "https://firebaserules.googleapis.com/v1/projects/$proj/rulesets" `
  -Headers @{ Authorization = "Bearer $tok" } `
  -ContentType 'application/json; charset=utf-8' -Body $bytes
$ruleset = $r.name
Write-Output "ruleset: $ruleset"

# El release va envuelto en "release" y con updateMask.
$rel = '{"release":{"name":"projects/' + $proj + '/releases/' + $release +
  '","rulesetName":"' + $ruleset + '"}}'
$rr = Invoke-RestMethod -Method Patch `
  -Uri "https://firebaserules.googleapis.com/v1/projects/$proj/releases/$release?updateMask=rulesetName" `
  -Headers @{ Authorization = "Bearer $tok" } `
  -ContentType 'application/json' -Body $rel
Write-Output "release actualizado: $($rr.updateTime)"
