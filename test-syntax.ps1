#!/usr/bin/env pwsh
# Quick syntax check

try {
    . ./src/shell/profile.ps1 2>&1 | Select-Object -First 20
    Write-Host "✓ profile.ps1 loads OK" -ForegroundColor Green
} catch {
    Write-Host "✗ profile.ps1 FEHLER:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

try {
    . ./monitor.ps1 2>&1 | Select-Object -First 20
    Write-Host "✓ monitor.ps1 loads OK" -ForegroundColor Green
} catch {
    Write-Host "✗ monitor.ps1 FEHLER:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
