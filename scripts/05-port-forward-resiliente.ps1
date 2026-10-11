# Port-forward que se reconecta solo si el pod al que estaba "pegado" muere.
# Uso: powershell -ExecutionPolicy Bypass -File scripts\06-port-forward-resiliente.ps1
# Ctrl+C para cortar del todo.
param(
  [string]$Service = "backend",
  [int]$LocalPort = 3000,
  [int]$RemotePort = 3000
)

while ($true) {
  Write-Host "Conectando port-forward a svc/$Service ($LocalPort -> $RemotePort)..." -ForegroundColor Cyan
  kubectl -n alentapp port-forward "svc/$Service" "${LocalPort}:${RemotePort}"
  Write-Host "Se cortó el túnel (probablemente murió el pod al que estaba conectado). Reconectando en 1s..." -ForegroundColor Yellow
  Start-Sleep -Seconds 1
}