. (Join-Path (Split-Path -Parent $PSScriptRoot) "lab_paths.ps1")
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lab_state.ps1")

function start-ai {
    param ([string]$Name)

    if (-not $Name) {
        $runningSessions = zellij ls 2>&1
        $i = 1
        while ($runningSessions -match "(?m)^quick-$i\b") { $i++ }
        $Name = "quick-$i"
    }

    $quickstartRoot = Get-LabQuickstartDirectory
    $sessionPath = Join-Path $quickstartRoot $Name
    if (-not (Test-Path $sessionPath)) {
        New-Item -Path $sessionPath -ItemType Directory -Force | Out-Null
        $templateRoot = Get-LabTemplateDirectory
        foreach ($f in @("MISSION.md", "USAGE.md", "AGENTS.md", "CLAUDE.md", "BOOTSTRAP.md", "SCRATCHPAD.md", "PROJECT_DNA.md", "PHASE.txt")) {
            $src = Join-Path $quickstartRoot $f
            if (-not (Test-Path $src)) { $src = Join-Path $templateRoot $f }
            if (Test-Path $src) { Copy-Item $src (Join-Path $sessionPath $f) -Force }
        }
    }

    $env:LAB_HOME = Get-LabHome
    $env:LAB_PROJECT_PATH = $sessionPath
    $env:LAB_SESSION_NAME = $Name
    Set-LabSessionState -SessionName $Name -ProjectPath $sessionPath -Mode "quickstart"
    zellij --layout (Get-LabLayoutPath "universal.kdl")
}

function start-ai-join {
    param ([string]$Name)
    if (-not $Name) {
        Get-ChildItem (Get-LabQuickstartDirectory) -Directory | Select-Object -ExpandProperty Name
        return
    }

    $sessionPath = Join-Path (Get-LabQuickstartDirectory) $Name
    if (-not (Test-Path $sessionPath)) {
        Write-Host "Session '$Name' nicht gefunden." -ForegroundColor Red
        return
    }

    $env:LAB_HOME = Get-LabHome
    $env:LAB_PROJECT_PATH = $sessionPath
    $env:LAB_SESSION_NAME = $Name
    Set-LabSessionState -SessionName $Name -ProjectPath $sessionPath -Mode "quickstart"
    zellij attach -c $Name
}

function init {
    & (Join-LabPath "init.ps1")
}

function lab {
    & (Join-LabPath "lab.ps1") $args[0] $args[1]
}

function lab-create {
    param ([string]$ProjectName, [string]$Typ)
    if (-not $ProjectName) {
        Write-Host "Usage: lab-create [Name] [dotnet|python|web]" -ForegroundColor Red
        return
    }

    $projectsDir = Ensure-LabDirectory (Get-LabProjectsDirectory)
    $baseDir = Read-Host "Wo soll der Projektordner '$ProjectName' liegen?"
    $fullPath = Join-Path $baseDir $ProjectName

    New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
    $fullPath | Out-File -FilePath (Join-Path $projectsDir "$ProjectName.path") -Force -Encoding UTF8

    $templateSource = Get-LabTemplateDirectory
    if (Test-Path $templateSource) {
        Copy-Item -Path (Join-Path $templateSource "*") -Destination $fullPath -Recurse -Force
        foreach ($file in @("MISSION.md", "USAGE.md")) {
            $filePath = Join-Path $fullPath $file
            if (Test-Path $filePath) {
                (Get-Content $filePath -Raw -Encoding UTF8) -replace '\[PROJEKTNAME\]', $ProjectName |
                    Set-Content $filePath -Encoding UTF8 -NoNewline
            }
        }
    }

    if ($Typ) {
        $typeSource = Get-LabTemplateDirectory $Typ
        if (Test-Path $typeSource) {
            Copy-Item -Path (Join-Path $typeSource "*") -Destination $fullPath -Recurse -Force
            Write-Host "Typ-Template '$Typ' angewendet." -ForegroundColor Cyan
        } else {
            Write-Host "Typ '$Typ' nicht gefunden. Verfuegbar: dotnet, python, web" -ForegroundColor Yellow
        }
    }

    Write-Host "Projekt '$ProjectName' erstellt: $fullPath" -ForegroundColor Green
}

function lab-join {
    param ([string]$ProjectName)
    if (-not $ProjectName) {
        Write-Host "Usage: lab-join [Name]" -ForegroundColor Red
        return
    }

    $configPathFile = Join-Path (Get-LabProjectsDirectory) "$ProjectName.path"
    if (-not (Test-Path $configPathFile)) {
        Write-Host "Projekt '$ProjectName' nicht gefunden." -ForegroundColor Red
        return
    }

    $root = (Get-Content $configPathFile -Raw -Encoding UTF8).Trim()
    $env:LAB_HOME = Get-LabHome
    $env:LAB_PROJECT_PATH = $root
    $env:LAB_SESSION_NAME = $ProjectName
    Set-LabSessionState -SessionName $ProjectName -ProjectPath $root -Mode "project"
    Set-Location $root
    zellij attach -c $ProjectName
}

function lab-status {
    $projects = Get-ChildItem (Join-Path (Get-LabProjectsDirectory) "*.path") -ErrorAction SilentlyContinue
    if (-not $projects) {
        Write-Host "Keine Projekte registriert." -ForegroundColor Yellow
        return
    }

    Write-Host "`nPROJEKTE" -ForegroundColor Cyan
    Write-Host "--------" -ForegroundColor Cyan
    foreach ($p in $projects) {
        $name = $p.BaseName
        $path = (Get-Content $p.FullName -Raw -Encoding UTF8).Trim()
        $ok = Test-Path $path
        $phase = if ($ok -and (Test-Path (Join-Path $path "PHASE.txt"))) { (Get-Content (Join-Path $path "PHASE.txt")).Trim() } else { "?" }
        $last = if ($ok) { (Get-Item $path).LastWriteTime.ToString("dd.MM HH:mm") } else { "---" }
        $tag = if ($ok) { "[OK]" } else { "[FEHLT]" }
        $color = if ($ok) { "Green" } else { "Red" }
        Write-Host ("  {0,-20} {1,-8} Phase: {2,-15} Zuletzt: {3}" -f $name, $tag, $phase, $last) -ForegroundColor $color
    }
    Write-Host ""
}

function lab-phase {
    param ([string]$Phase)
    if (-not $Phase) {
        Write-Host "Usage: lab-phase [Brainstorming|Entwicklung|Debugging]" -ForegroundColor Red
        return
    }

    $root = Get-LabCurrentProjectPath -SessionName $env:LAB_SESSION_NAME
    if (-not (Test-Path $root)) {
        Write-Host "Projektordner nicht gefunden." -ForegroundColor Red
        return
    }

    $Phase | Out-File (Join-Path $root "PHASE.txt") -Force -Encoding UTF8
    Write-Host "Phase gesetzt: $Phase" -ForegroundColor Cyan
}

function lab-open {
    $path = Get-LabCurrentProjectPath -SessionName $env:LAB_SESSION_NAME
    if (Test-Path $path) { explorer $path } else { Write-Host "Pfad nicht gefunden: $path" -ForegroundColor Red }
}

function lab-report {
    $root = Get-LabCurrentProjectPath -SessionName $env:LAB_SESSION_NAME
    if (-not (Test-Path $root)) {
        Write-Host "Projektordner nicht gefunden." -ForegroundColor Red
        return
    }

    $projectName = Split-Path $root -Leaf
    $date = Get-Date -Format "yyyy-MM-dd"
    $reportPath = Join-Path $root "REPORT_$date.md"

    $content = "# PROJEKTBERICHT: $projectName`n"
    $content += "_Erstellt: $(Get-Date -Format 'dd.MM.yyyy HH:mm')_`n`n"

    foreach ($file in @("MISSION.md", "PROJECT_DNA.md", "USAGE.md")) {
        $filePath = Join-Path $root $file
        if (Test-Path $filePath) {
            $content += "---`n`n"
            $content += (Get-Content $filePath -Raw -Encoding UTF8).Trim()
            $content += "`n`n"
        }
    }

    $content | Out-File $reportPath -Encoding UTF8
    Write-Host "Bericht erstellt: $reportPath" -ForegroundColor Green
    Start-Process $reportPath
}

function lab-clean {
    $sessions = @(Get-LabKnownSessionNames)
    if (-not $sessions -or $sessions.Count -eq 0) {
        Write-Host "Keine bekannten Lab-Sessions gefunden." -ForegroundColor Yellow
        return
    }

    Write-Host "Diese Lab-Sessions werden beendet:" -ForegroundColor Yellow
    $sessions | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }

    $confirm = Read-Host "Weiter mit lab-clean? (j/n)"
    if ($confirm -notin @("j", "J", "y", "Y")) {
        Write-Host "Abgebrochen." -ForegroundColor Yellow
        return
    }

    foreach ($name in $sessions) {
        zellij delete-session $name 2>$null
    }

    Write-Host "Lab-Sessions bereinigt." -ForegroundColor Green
}

function lab-delete {
    param (
        [string]$ProjectName,
        [switch]$DeleteFiles
    )

    if (-not $ProjectName) {
        Write-Host "Usage: lab-delete [Name] [-DeleteFiles]" -ForegroundColor Red
        return
    }

    $configPathFile = Join-Path (Get-LabProjectsDirectory) "$ProjectName.path"
    if (-not (Test-Path $configPathFile)) {
        Write-Host "Projekt '$ProjectName' nicht gefunden." -ForegroundColor Red
        return
    }

    $projectPath = (Get-Content $configPathFile -Raw -Encoding UTF8).Trim()

    Write-Host "Projekt: $ProjectName" -ForegroundColor Yellow
    Write-Host "Pfad: $projectPath" -ForegroundColor Yellow
    if ($DeleteFiles) {
        Write-Host "Dateisystem: Projektordner wird ebenfalls geloescht." -ForegroundColor Yellow
    } else {
        Write-Host "Dateisystem: Projektordner bleibt erhalten." -ForegroundColor Yellow
    }

    $confirm = Read-Host "Projekt wirklich loeschen? (j/n)"
    if ($confirm -notin @("j", "J", "y", "Y")) {
        Write-Host "Abgebrochen." -ForegroundColor Yellow
        return
    }

    zellij delete-session $ProjectName 2>$null
    Remove-LabSessionState -SessionName $ProjectName
    Remove-Item -LiteralPath $configPathFile -Force

    if ($DeleteFiles -and $projectPath -and (Test-Path $projectPath)) {
        Remove-Item -LiteralPath $projectPath -Recurse -Force
    }

    Write-Host "Projekt '$ProjectName' entfernt." -ForegroundColor Green
}

function lab-complete {
    param([string]$ProjectName)
    if (-not $ProjectName) {
        Write-Host "Usage: lab-complete [Name]" -ForegroundColor Red
        return
    }

    $configPathFile = Join-Path (Get-LabProjectsDirectory) "$ProjectName.path"
    if (-not (Test-Path $configPathFile)) {
        Write-Host "Projekt '$ProjectName' nicht gefunden." -ForegroundColor Red
        return
    }

    $projectPath = (Get-Content $configPathFile -Raw -Encoding UTF8).Trim()
    $brainPath   = Join-Path (Get-LabHome) "WORKBENCH_BRAIN.md"
    $date        = Get-Date -Format "yyyy-MM-dd"

    # PROJECT_DNA.md anzeigen wenn vorhanden
    $dnaPath    = Join-Path $projectPath "PROJECT_DNA.md"
    $dnaContent = if (Test-Path $dnaPath) { (Get-Content $dnaPath -Raw -Encoding UTF8).Trim() } else { "" }
    if ($dnaContent) {
        Write-Host "`n=== PROJECT_DNA.md ===" -ForegroundColor Cyan
        Write-Host $dnaContent
        Write-Host "======================`n" -ForegroundColor Cyan
    }

    # Lektionen einsammeln
    Write-Host "Lektionen fuer WORKBENCH_BRAIN.md eingeben:" -ForegroundColor Yellow
    Write-Host "  Format: [tag] Lektion   (z.B. [python] Immer venv vor Start aktivieren)" -ForegroundColor DarkGray
    Write-Host "  Leer lassen + Enter zum Beenden`n" -ForegroundColor DarkGray

    $newLessons = [System.Collections.Generic.List[string]]::new()
    $i = 1
    while ($true) {
        $entry = Read-Host "  Lektion $i"
        if (-not $entry.Trim()) { break }
        $newLessons.Add("[$date] [$ProjectName] $entry")
        $i++
    }

    if ($newLessons.Count -gt 0) {
        if (-not (Test-Path $brainPath)) {
            Set-Content $brainPath -Value "# WORKBENCH BRAIN`nDestillierte Lektionen aus abgeschlossenen Projekten. Max 50 Eintraege, aelteste rotieren raus.`nNur bei Bedarf lesen. Nicht automatisch laden.`n`n---`n" -Encoding UTF8
        }

        Add-Content $brainPath -Value ($newLessons -join "`n") -Encoding UTF8

        # Rotation: max 50 Eintraege (Zeilen die mit [20xx- beginnen)
        $allLines = Get-Content $brainPath -Encoding UTF8
        $header   = $allLines | Where-Object { $_ -notmatch '^\[20\d\d-' }
        $entries  = @($allLines | Where-Object { $_ -match '^\[20\d\d-' })
        if ($entries.Count -gt 50) {
            $entries = $entries | Select-Object -Last 50
            ($header + $entries) -join "`n" | Set-Content $brainPath -Encoding UTF8
        }

        Write-Host "`n$($newLessons.Count) Lektion(en) in WORKBENCH_BRAIN.md eingetragen." -ForegroundColor Green
    }

    # Abschlussbericht generieren
    $reportPath    = Join-Path $projectPath ("REPORT_" + $date + ".md")
    $reportContent = "# PROJEKTBERICHT: $ProjectName`n_Abgeschlossen: $(Get-Date -Format 'dd.MM.yyyy HH:mm')_`n`n"
    foreach ($f in @("MISSION.md", "PROJECT_DNA.md", "USAGE.md")) {
        $fp = Join-Path $projectPath $f
        if (Test-Path $fp) {
            $reportContent += "---`n`n" + (Get-Content $fp -Raw -Encoding UTF8).Trim() + "`n`n"
        }
    }
    $reportContent | Out-File $reportPath -Encoding UTF8
    Write-Host "Abschlussbericht erstellt: $reportPath" -ForegroundColor Green

    # Projekt aus Registry entfernen (Dateien bleiben)
    $confirm = Read-Host "`nProjekt aus Registry entfernen? Ordner und Dateien bleiben erhalten. (j/n)"
    if ($confirm -in @("j", "J", "y", "Y")) {
        zellij delete-session $ProjectName 2>$null
        Remove-LabSessionState -SessionName $ProjectName
        Remove-Item -LiteralPath $configPathFile -Force
        Write-Host "Projekt '$ProjectName' abgeschlossen. Ordner: $projectPath" -ForegroundColor Green
    }
}
