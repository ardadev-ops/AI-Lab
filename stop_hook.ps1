. (Join-Path $PSScriptRoot "lab_paths.ps1")
. (Join-Path $PSScriptRoot "lab_state.ps1")

$projectPath = Get-LabCurrentProjectPath -SessionName $env:LAB_SESSION_NAME

if (-not $projectPath -or -not (Test-Path $projectPath)) { exit 0 }

$quickstartRoot = Get-LabQuickstartDirectory
$isQuickstart = $projectPath.StartsWith($quickstartRoot)
$sessionName = if ($env:LAB_SESSION_NAME) { $env:LAB_SESSION_NAME } else { Split-Path $projectPath -Leaf }

$date = Get-Date -Format "yyyy-MM-dd HH:mm"
$phase = "?"
$phaseFile = Join-Path $projectPath "PHASE.txt"
if (Test-Path $phaseFile) { $phase = (Get-Content $phaseFile -Encoding UTF8).Trim() }

# 1. USAGE.md aktualisieren
$usagePath = Join-Path $projectPath "USAGE.md"
if (Test-Path $usagePath) {
    $line = "- ``$date`` | Session: $sessionName | Phase: $phase | Session beendet"
    Add-Content -Path $usagePath -Value $line -Encoding UTF8
}

# 2. Git Checkpoint (nur bei echten Projekten)
if (-not $isQuickstart) {
    $gitDir = Join-Path $projectPath ".git"
    if (-not (Test-Path $gitDir)) {
        git -C $projectPath init 2>$null
        git -C $projectPath config user.email "lab@local" 2>$null
        git -C $projectPath config user.name "Lab" 2>$null
    }
    $changes = git -C $projectPath status --porcelain 2>$null
    if ($changes) {
        git -C $projectPath add -A 2>$null
        git -C $projectPath commit -m "Checkpoint: $date [$phase]" 2>$null
    }
}

# 3. SCRATCHPAD-Cleanup: ALLE Eintraege archivieren, SCRATCHPAD zuruecksetzen
$scratchpadPath = Join-Path $projectPath "SCRATCHPAD.md"
if (Test-Path $scratchpadPath) {
    $raw = Get-Content $scratchpadPath -Raw -Encoding UTF8

    # Guard: Nur archivieren wenn echte Handoff-Eintraege existieren (mit Zeitstempel)
    $hasRealEntries = [regex]::IsMatch($raw, '(?m)^## \[(Claude|Codex)[^\]]*\]\s*\d{4}-\d{2}-\d{2}')

    if ($hasRealEntries) {
        $match = [regex]::Match($raw, '(?m)^## \[(Claude|Codex)')
        if ($match.Success) {
            $header = $raw.Substring(0, $match.Index)
            $entriesRaw = $raw.Substring($match.Index)

            $entryParts = [regex]::Split($entriesRaw, '(?m)(?=^## \[(Claude|Codex))') |
                Where-Object { $_ -match '\S' }

            if ($entryParts.Count -gt 0) {
                # Alle Eintraege archivieren
                $archivePath = Join-Path $projectPath "SCRATCHPAD_archive.md"
                $archivePrefix = if (-not (Test-Path $archivePath)) { "# SCRATCHPAD Archive`n`n" } else { "" }
                Add-Content -Path $archivePath -Value ($archivePrefix + ($entryParts -join "")) -Encoding UTF8

                # SCRATCHPAD zu default Template zuruecksetzen
                $defaultTemplate = @"
# SCRATCHPAD: Handoff zwischen Claude und Codex

Wenn du eine Aufgabe abgeschlossen hast oder der andere Agent etwas uebernehmen soll, schreibe ans Ende:

`## [Claude --> Codex] DATUM HH:MM
**Status**: erledigt | blockiert | Frage
**Was wurde gemacht**: ...
**Was Codex tun soll**: ...
**Relevante Dateien**: src/...
---

`## [Codex --> Claude] DATUM HH:MM
**Status**: erledigt | blockiert | Frage
**Was wurde gemacht**: ...
**Was Claude tun soll**: ...
**Relevante Dateien**: src/...
---
"@
                Set-Content -Path $scratchpadPath -Value $defaultTemplate -Encoding UTF8 -NoNewline
            }
        }
    }
}

# 4. Collab-System Cleanup: Locks freigeben + Watcher stoppen
. (Join-Path $PSScriptRoot "lab_collab.ps1")

$locksDir = Get-LabLockDirectory -ProjectPath $projectPath
if (Test-Path $locksDir) {
    Get-ChildItem -Path $locksDir -Filter "*.lock" -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

$watcherJobName = "lab-watcher-$(Split-Path -Leaf $projectPath)"
Stop-Job -Name $watcherJobName -ErrorAction SilentlyContinue
Remove-Job -Name $watcherJobName -ErrorAction SilentlyContinue
