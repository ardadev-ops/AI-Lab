# init_project.ps1
# Dieses Skript bereitet jeden beliebigen Projektordner fuer mein AI-Labor vor

$targetDir = Get-Location

Write-Host "Initialisiere Labor-Struktur in: $targetDir" -ForegroundColor Cyan

# 1. Kopiere Template-Dateien
$labHome = if ($env:LAB_HOME) { $env:LAB_HOME } else { Split-Path -Parent $PSScriptRoot }
$templateDir = Join-Path $labHome "templates"
if (Test-Path $templateDir) {
    @("MISSION.md", "CLAUDE.md", "BOOTSTRAP.md", "PROJECT_DNA.md", "SCRATCHPAD.md") | ForEach-Object {
        $src = Join-Path $templateDir $_
        if (Test-Path $src) { Copy-Item $src -Destination $_ -Force }
    }
}

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
