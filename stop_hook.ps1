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
