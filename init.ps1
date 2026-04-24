# init_project.ps1
# Dieses Skript bereitet jeden beliebigen Projektordner fuer mein AI-Labor vor

$targetDir = Get-Location

Write-Host "Initialisiere Labor-Struktur in: $targetDir" -ForegroundColor Cyan

# 1. Erstelle die notwendigen Dateien
@"
# MISSION: [Projektname eintragen]

## Ziel
- [ ] Ziel in 1-2 klaren Saetzen festhalten

## Next Up
- [ ] Naechsten sinnvollen Schritt eintragen
- [ ] Zweiten Schritt eintragen

## In Arbeit
- [~] Aktuellen Task hierhin ziehen

## Erledigt
- [x] Fertige Punkte hier sammeln

## Risiken / Offene Fragen
- Blocker, Unsicherheiten oder Entscheidungen hier notieren
"@ | Set-Content -Path "MISSION.md" -Encoding UTF8

@"
# USAGE BOARD - [Projektname eintragen]

## Live
- Claude Tokens werden oben im Pane aus lokalen Logs berechnet, wenn verfuegbar.
- Codex- und Gemini-Tokens sind aktuell noch nicht angebunden.

## Heute
- Start / Stop / Phasenwechsel und kurze Notizen laufen unten in den Verlauf.

## Verlauf
"@ | Set-Content -Path "USAGE.md" -Encoding UTF8

# 2. Erstelle einen Ordner fuer lokale Extensions/Plugins (optional)
New-Item -Path ".lab_extensions" -ItemType Directory -Force | Out-Null

Write-Host "Labor-Struktur erfolgreich erstellt!" -ForegroundColor Green
Write-Host "Starte jetzt 'start-ai', um das Zellij-Layout zu laden." -ForegroundColor Yellow
