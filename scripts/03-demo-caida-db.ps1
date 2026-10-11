# Pega cada 0.5s a /api/v1/socios y muestra hora + resultado en vivo.
# Uso: powershell -ExecutionPolicy Bypass -File scripts\05-watch-recovery.ps1
# Ctrl+C para cortar.
while ($true) {
  $t = Get-Date -Format "HH:mm:ss.fff"
  try {
    $r = Invoke-WebRequest -Uri "http://localhost:3000/api/v1/socios" -UseBasicParsing -TimeoutSec 2
    Write-Host "$t -> $($r.StatusCode) OK" -ForegroundColor Green
  } catch {
    Write-Host "$t -> FALLA" -ForegroundColor Red
  }
  Start-Sleep -Milliseconds 500
}