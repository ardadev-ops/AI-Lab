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

# 3. SCRATCHPAD-Rotation: letzte 5 Einträge behalten, Rest archivieren
$scratchpadPath = Join-Path $projectPath "SCRATCHPAD.md"
if (Test-Path $scratchpadPath) {
    $raw = Get-Content $scratchpadPath -Raw -Encoding UTF8

    $match = [regex]::Match($raw, '(?m)^## \[(Claude|Codex)')
    if ($match.Success) {
        $header = $raw.Substring(0, $match.Index)
        $entriesRaw = $raw.Substring($match.Index)

        $entryParts = [regex]::Split($entriesRaw, '(?m)(?=^## \[(Claude|Codex))') |
            Where-Object { $_ -match '\S' }

        if ($entryParts.Count -gt 5) {
            $toArchive = $entryParts[0..($entryParts.Count - 6)]
            $toKeep    = $entryParts[($entryParts.Count - 5)..($entryParts.Count - 1)]

            $archivePath = Join-Path $projectPath "SCRATCHPAD_archive.md"
            $archivePrefix = if (-not (Test-Path $archivePath)) { "# SCRATCHPAD Archive`n`n" } else { "" }
            Add-Content -Path $archivePath -Value ($archivePrefix + ($toArchive -join "")) -Encoding UTF8

            $newContent = $header.TrimEnd() + "`n`n" + ($toKeep -join "")
            Set-Content -Path $scratchpadPath -Value $newContent -Encoding UTF8 -NoNewline
        }
    }
}
