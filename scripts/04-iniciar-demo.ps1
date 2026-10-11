# Levanta los dos port-forward resilientes (backend y frontend), cada uno en su
# propia ventana nueva de PowerShell. Cerrá esas ventanas al terminar la demo
# (o Ctrl+C en cada una).
# Uso: powershell -ExecutionPolicy Bypass -File scripts\04-iniciar-demo.ps1

$scriptDir = $PSScriptRoot

Write-Host "Abriendo port-forward del backend (puerto 3000)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
  "-NoExit", "-ExecutionPolicy", "Bypass", "-File",
  "$scriptDir\05-port-forward-resiliente.ps1",
  "-Service", "backend", "-LocalPort", "3000", "-RemotePort", "3000"
)

Write-Host "Abriendo port-forward del frontend (puerto 8080)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
  "-NoExit", "-ExecutionPolicy", "Bypass", "-File",
  "$scriptDir\05-port-forward-resiliente.ps1",
  "-Service", "frontend", "-LocalPort", "8080", "-RemotePort", "8080"
)

Write-Host ""
Write-Host "Listo. Dos ventanas nuevas abiertas:" -ForegroundColor Green
Write-Host "  Backend  -> http://localhost:3000"
Write-Host "  Frontend -> http://localhost:8080"
Write-Host "Dejalas abiertas durante toda la demo."