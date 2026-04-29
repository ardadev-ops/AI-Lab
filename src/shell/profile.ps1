$_labRoot = if ($PSScriptRoot) { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) } elseif ($env:LAB_HOME) { $env:LAB_HOME } else { $null }
if ($_labRoot) {
    . (Join-Path $_labRoot "lab_paths.ps1")
    . (Join-Path $_labRoot "lab_state.ps1")

    # Auto-Cleanup: Verwaiste/beendete Background-Jobs entfernen
    @(Get-Job -Name "lab-watcher-*" -ErrorAction SilentlyContinue | Where-Object { $_.State -ne "Running" }) |
        ForEach-Object { Remove-Job $_ -Force -ErrorAction SilentlyContinue 2>$null }
}

function start-ai {
    param ([string]$Name)

    # Cleanup: alte/verwaiste Jobs entfernen BEVOR neue Session startet
    $allJobs = @(Get-Job -Name "lab-watcher-*" -ErrorAction SilentlyContinue)
    foreach ($job in $allJobs) {
        if ($job.State -ne "Running") {
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        }
    }

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
    }

    # Template-Dateien kopieren (immer, auch wenn Ordner existiert)
    $templateRoot = Get-LabTemplateDirectory
    foreach ($f in @("MISSION.md", "USAGE.md", "AGENTS.md", "CLAUDE.md", "BOOTSTRAP.md", "SCRATCHPAD.md", "PROJECT_DNA.md")) {
        $src = Join-Path $templateRoot $f
        if (Test-Path $src) { Copy-Item $src (Join-Path $sessionPath $f) -Force }
    }

    # PHASE.txt auf Brainstorming zurücksetzen
    "Brainstorming" | Set-Content (Join-Path $sessionPath "PHASE.txt") -Encoding UTF8

    # MISSION.md Header mit Datum aktualisieren
    $missionPath = Join-Path $sessionPath "MISSION.md"
    $sessionDate = (Get-Date -Format "yyyy-MM-dd HH:mm")
    if (Test-Path $missionPath) {
        $content = (Get-Content $missionPath -Raw -Encoding UTF8) -replace '_Session: \[DATUM\]_', "_Session: $sessionDate_"
        Set-Content $missionPath $content -Encoding UTF8 -NoNewline
    }

    $env:LAB_HOME = Get-LabHome
    $env:LAB_PROJECT_PATH = $sessionPath
    $env:LAB_SESSION_NAME = $Name
    Set-LabSessionState -SessionName $Name -ProjectPath $sessionPath -Mode "quickstart"
    (Get-Date -Format "o") | Set-Content (Join-Path $sessionPath "SESSION_START.txt") -Encoding UTF8

    # Collab-Watcher starten
    . (Join-Path $env:LAB_HOME "lab_collab.ps1")
    $watcherJob = Start-LabWatcher -ProjectPath $sessionPath -IntervalMs 1000 -WatchFiles @("MISSION.md", "SCRATCHPAD.md")
    Write-Host "Collab Watcher läuft: $watcherJob" -ForegroundColor DarkGray

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
    # Cleanup: verwaiste Jobs entfernen
    @(Get-Job -Name "lab-watcher-*" -ErrorAction SilentlyContinue | Where-Object { $_.State -ne "Running" }) |
        ForEach-Object { Remove-Job $_ -Force -ErrorAction SilentlyContinue }

    & (Join-LabPath "lab.ps1") $args[0] $args[1]
}

function lab-create {
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [string]$Typ,
        [string]$Path
    )

    # Base directory: explicit path, oder Benutzer wird gefragt
    if ($Path) {
        $baseDir = $Path
    } else {
        Write-Host "Wohin soll das Projekt '$ProjectName' erstellt werden?" -ForegroundColor Cyan
        Write-Host "Aktuelles Verzeichnis: $(Get-Location)" -ForegroundColor DarkGray
        $baseDir = Read-Host "Pfad eingeben (oder leer für aktuelles Verzeichnis)"
        if (-not $baseDir) {
            $baseDir = (Get-Location).Path
        }
    }

    if (-not (Test-Path $baseDir -PathType Container)) {
        Write-Host "Verzeichnis nicht gefunden: $baseDir" -ForegroundColor Red
        return
    }

    $fullPath = Join-Path $baseDir $ProjectName

    # Falls Ordner schon existiert, Warnung
    if (Test-Path $fullPath) {
        Write-Host "Verzeichnis existiert bereits: $fullPath" -ForegroundColor Yellow
        $confirm = Read-Host "Fortfahren und überschreiben? (j/n)"
        if ($confirm -notin @("j", "J", "y", "Y")) {
            Write-Host "Abgebrochen." -ForegroundColor Yellow
            return
        }
    }

    New-Item -Path $fullPath -ItemType Directory -Force | Out-Null

    # Registriere das Projekt
    $projectsDir = Ensure-LabDirectory (Get-LabProjectsDirectory)
    $fullPath | Out-File -FilePath (Join-Path $projectsDir "$ProjectName.path") -Force -Encoding UTF8

    # Kopiere Template-Dateien
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
        Write-Host "Template-Dateien kopiert." -ForegroundColor Green
    }

    # Typ-spezifisches Template
    if ($Typ) {
        $typeSource = Get-LabTemplateDirectory $Typ
        if (Test-Path $typeSource) {
            Copy-Item -Path (Join-Path $typeSource "*") -Destination $fullPath -Recurse -Force
            Write-Host "Typ-Template '$Typ' angewendet." -ForegroundColor Cyan
        } else {
            Write-Host "Typ '$Typ' nicht gefunden. Verfuegbar: dotnet, python, web" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "[OK] Projekt '$ProjectName' erstellt:" -ForegroundColor Green
    Write-Host "  $fullPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Nächste Schritte:" -ForegroundColor Cyan
    Write-Host "  1. cd $fullPath" -ForegroundColor DarkGray
    Write-Host "  2. lab-join $ProjectName" -ForegroundColor DarkGray
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
        zellij delete-session $name --force 2>$null
    }

    Write-Host "Lab-Sessions bereinigt." -ForegroundColor Green
}

function Strip-Ansi([string]$s) {
    return ($s -replace '\x1b\[[0-9;]*[A-Za-z]', '')
}

function lab-sessions {
    $running = @(zellij ls 2>&1 | Where-Object { $_ -match '\S' })

    if (-not $running -or $running.Count -eq 0) {
        Write-Host "Keine laufenden Zellij-Sessions." -ForegroundColor Yellow
        return
    }

    $quickstartRoot = Get-LabQuickstartDirectory

    Write-Host "`nLAUFENDE SESSIONS ($($running.Count))" -ForegroundColor Cyan
    Write-Host ("-" * 50) -ForegroundColor Cyan

    foreach ($line in $running) {
        $name = (Strip-Ansi $line) -replace '\s.*', ''
        $name = $name.Trim()
        if (-not $name) { continue }

        $state = Get-LabSessionState -SessionName $name
        $path  = if ($state -and $state.ProjectPath) { $state.ProjectPath } else { "" }
        $phase = "?"
        $typ   = "unbekannt"

        if ($path -and (Test-Path $path)) {
            $pf = Join-Path $path "PHASE.txt"
            if (Test-Path $pf) { $phase = (Get-Content $pf -Encoding UTF8).Trim() }
            $typ = if ($path.StartsWith($quickstartRoot)) { "quickstart" } else { "projekt" }
        }

        $color = if ($typ -eq "quickstart") { "Cyan" } else { "Green" }
        Write-Host ("  {0,-20} [{1,-10}] Phase: {2}" -f $name, $typ, $phase) -ForegroundColor $color
    }
    Write-Host ""
    Write-Host "  lab-kill [Name...]  -> gezielt beenden" -ForegroundColor DarkGray
    Write-Host "  lab-killall         -> alle beenden`n" -ForegroundColor DarkGray
}

function lab-killall {
    $running = @(zellij ls 2>&1 | Where-Object { $_ -match '\S' } | ForEach-Object { ((Strip-Ansi $_) -replace '\s.*', '').Trim() } | Where-Object { $_ })

    if (-not $running -or $running.Count -eq 0) {
        Write-Host "Keine laufenden Sessions." -ForegroundColor Yellow
        return
    }

    Write-Host "Laufende Sessions die beendet werden:" -ForegroundColor Yellow
    $running | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }

    $confirm = Read-Host "`nAlle $($running.Count) Sessions beenden? (j/n)"
    if ($confirm -notin @("j", "J", "y", "Y")) {
        Write-Host "Abgebrochen." -ForegroundColor Yellow
        return
    }

    $labHome = Get-LabHome
    foreach ($name in $running) {
        $state = Get-LabSessionState -SessionName $name
        if ($state -and $state.ProjectPath) {
            # Stop-Hook aufrufen für Cleanup (Logs, Git-Checkpoint, Locks)
            $env:LAB_PROJECT_PATH = $state.ProjectPath
            $env:LAB_SESSION_NAME = $name
            & "$labHome\stop_hook.ps1" 2>$null
        }

        # Session killen
        zellij delete-session $name --force 2>$null
        Remove-LabSessionState -SessionName $name

        # Background-Watcher-Jobs aufräumen
        $watcherJobs = @(Get-Job -Name "lab-watcher-$name" -ErrorAction SilentlyContinue)
        foreach ($job in $watcherJobs) {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "Alle Sessions beendet." -ForegroundColor Green
}

function lab-kill {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Names)

    if (-not $Names -or $Names.Count -eq 0) {
        Write-Host "Usage: lab-kill [Name1] [Name2] ..." -ForegroundColor Red
        Write-Host "       lab-sessions  -> laufende Sessions anzeigen" -ForegroundColor DarkGray
        return
    }

    foreach ($name in $Names) {
        $name = $name.Trim()
        zellij delete-session $name --force 2>$null
        Remove-LabSessionState -SessionName $name
        Write-Host "Beendet: $name" -ForegroundColor Green
    }
}

function lab-gc {
    $zellijSessions = @(
        zellij ls 2>&1 |
        Where-Object { $_ -match '\S' } |
        ForEach-Object { ((Strip-Ansi $_) -replace '\s.*', '').Trim() } |
        Where-Object { $_ }
    )

    $stateDir  = Get-LabSessionStateDirectory
    $labSessions = @(
        Get-ChildItem $stateDir -Filter *.json -File -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty BaseName
    )

    $orphans = @($zellijSessions | Where-Object { $_ -notin $labSessions })
    $stale   = @($labSessions   | Where-Object { $_ -notin $zellijSessions })

    $hasWork = $false

    if ($orphans.Count -gt 0) {
        $hasWork = $true
        Write-Host "`nORPHAN SESSIONS ($($orphans.Count))  --  Zellij kennt sie, Lab nicht:" -ForegroundColor Yellow
        $orphans | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }

        $confirm = Read-Host "`nOrphans jetzt beenden? (j/n)"
        if ($confirm -in @("j", "J", "y", "Y")) {
            foreach ($name in $orphans) {
                zellij delete-session $name --force 2>$null
                Write-Host "  Beendet: $name" -ForegroundColor Green
            }
        }
    }

    if ($stale.Count -gt 0) {
        $hasWork = $true
        Write-Host "`nSTALE STATE FILES ($($stale.Count))  --  State-Eintraege ohne laufende Session:" -ForegroundColor DarkGray
        $stale | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkGray }

        $confirm = Read-Host "`nState-Files bereinigen? (j/n)"
        if ($confirm -in @("j", "J", "y", "Y")) {
            foreach ($name in $stale) {
                Remove-LabSessionState -SessionName $name
                Write-Host "  Entfernt: $name" -ForegroundColor Green
            }
        }
    }

    if (-not $hasWork) {
        Write-Host "`nAlles sauber -- keine Leichen gefunden." -ForegroundColor Green
    }
    Write-Host ""
}

function lab-switch {
    param([string]$Name)

    if (-not $Name) {
        $sessions = @(
            zellij ls 2>&1 |
            Where-Object { $_ -match '\S' } |
            ForEach-Object { ((Strip-Ansi $_) -replace '\s.*', '').Trim() } |
            Where-Object { $_ }
        )
        if (-not $sessions -or $sessions.Count -eq 0) {
            Write-Host "Keine laufenden Sessions." -ForegroundColor Yellow
        } else {
            Write-Host "`nLaufende Sessions:" -ForegroundColor Cyan
            $sessions | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            Write-Host ""
            Write-Host "Usage: lab-switch [Name]" -ForegroundColor DarkGray
        }
        return
    }

    $running = @(
        zellij ls 2>&1 |
        Where-Object { $_ -match '\S' } |
        ForEach-Object { ((Strip-Ansi $_) -replace '\s.*', '').Trim() } |
        Where-Object { $_ }
    )

    if ($Name -notin $running) {
        Write-Host "Session '$Name' laeuft nicht. Laufende Sessions:" -ForegroundColor Red
        $running | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        return
    }

    zellij attach -c $Name
}

function lab-dashboard {
    function Get-DashTokStr([int64]$t) {
        $inv = [System.Globalization.CultureInfo]::InvariantCulture
        if ($t -ge 1000000) { return ($t / 1000000.0).ToString("F1", $inv) + "M" }
        if ($t -ge 1000)    { return [string][math]::Round($t / 1000) + "k" }
        return "$t"
    }

    function Get-DashName([string]$nm) {
        if ($nm.Length -gt 19) { return $nm.Substring(0, 18) + ".." }
        return $nm
    }

    function Get-DashLogFile([string]$path) {
        $key = ($path -replace '[^A-Za-z0-9]', '-')
        $dir = Join-Path $HOME ".claude\projects\$key"
        if (-not (Test-Path $dir)) { return $null }
        return Get-ChildItem $dir -Filter *.jsonl -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
    }

    function Get-DashTotalTokens([string]$path) {
        $log = Get-DashLogFile $path
        if (-not $log) { return $null }
        $total = [int64]0
        foreach ($line in Get-Content $log.FullName -Encoding UTF8 -ErrorAction SilentlyContinue) {
            try { $e = $line | ConvertFrom-Json } catch { continue }
            $u = $e.message.usage
            if (-not $u) { continue }
            if ($u.input_tokens)                { $total += [int64]$u.input_tokens }
            if ($u.output_tokens)               { $total += [int64]$u.output_tokens }
            if ($u.cache_read_input_tokens)     { $total += [int64]$u.cache_read_input_tokens }
            if ($u.cache_creation_input_tokens) { $total += [int64]$u.cache_creation_input_tokens }
        }
        return $total
    }

    function Get-DashLastActivity([string]$path) {
        $log = Get-DashLogFile $path
        if (-not $log) { return $null }
        $last = $log.LastWriteTime
        if ($last.Date -eq (Get-Date).Date) { return $last.ToString("HH:mm") }
        return $last.ToString("dd.MM")
    }

    function Write-DashRow([string]$nm, [string]$status, [string]$phase, [string]$tokStr, [string]$activity) {
        Write-Host -NoNewline ("  {0,-20}" -f (Get-DashName $nm))
        $sc = if ($status -like "*laufend*") { "Green" } elseif ($status -like "*FEHLT*") { "Red" } else { "DarkGray" }
        Write-Host -NoNewline ("{0,-12}" -f $status) -ForegroundColor $sc
        Write-Host -NoNewline ("{0,-16}" -f $phase) -ForegroundColor White
        Write-Host -NoNewline ("{0,7} tok" -f $tokStr) -ForegroundColor DarkGray
        if ($activity) { Write-Host ("   {0}" -f $activity) -ForegroundColor DarkGray } else { Write-Host "" }
    }

    $running = @(
        zellij ls 2>&1 |
        Where-Object { $_ -match '\S' } |
        ForEach-Object { ((Strip-Ansi $_) -replace '\s.*', '').Trim() } |
        Where-Object { $_ }
    )

    $w   = 66
    $bar = "=" * $w
    $now = Get-Date -Format "ddd dd.MM  HH:mm"
    $hdr = "  LAB DASHBOARD"

    Clear-Host
    Write-Host $bar -ForegroundColor Cyan
    Write-Host ($hdr + (" " * ($w - $hdr.Length - $now.Length)) + $now) -ForegroundColor Cyan
    Write-Host $bar -ForegroundColor Cyan

    $grandTotal = [int64]0
    $count = 0

    # Quickstart
    $quickRoot = Get-LabQuickstartDirectory
    $quickDirs = @(
        Get-ChildItem $quickRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName "PHASE.txt") } |
        Sort-Object Name
    )
    if ($quickDirs.Count -gt 0) {
        Write-Host "`n  QUICKSTART" -ForegroundColor DarkGray
        foreach ($d in $quickDirs) {
            $phase  = (Get-Content (Join-Path $d.FullName "PHASE.txt") -Encoding UTF8 -ErrorAction SilentlyContinue).Trim()
            $status = if ($d.Name -in $running) { "[laufend] " } else { "[gestoppt]" }
            $tok    = Get-DashTotalTokens $d.FullName
            $tokStr = if ($null -ne $tok) { Get-DashTokStr $tok } else { "--" }
            $act    = Get-DashLastActivity $d.FullName
            Write-DashRow $d.Name $status $phase $tokStr $act
            if ($tok) { $grandTotal += $tok }
            $count++
        }
    }

    # Projekte
    $projFiles = @(
        Get-ChildItem (Get-LabProjectsDirectory) -Filter *.path -File -ErrorAction SilentlyContinue |
        Sort-Object BaseName
    )
    if ($projFiles.Count -gt 0) {
        Write-Host "`n  PROJEKTE" -ForegroundColor DarkGray
        foreach ($pf in $projFiles) {
            $path = (Get-Content $pf.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue).Trim()
            if (-not $path -or -not (Test-Path $path)) {
                Write-DashRow $pf.BaseName "[FEHLT]   " "" "--" $null
                $count++
                continue
            }
            $phasePath = Join-Path $path "PHASE.txt"
            $phase  = if (Test-Path $phasePath) { (Get-Content $phasePath -Encoding UTF8).Trim() } else { "" }
            $status = if ($pf.BaseName -in $running) { "[laufend] " } else { "[gestoppt]" }
            $tok    = Get-DashTotalTokens $path
            $tokStr = if ($null -ne $tok) { Get-DashTokStr $tok } else { "--" }
            $act    = Get-DashLastActivity $path
            Write-DashRow $pf.BaseName $status $phase $tokStr $act
            if ($tok) { $grandTotal += $tok }
            $count++
        }
    }

    if ($count -eq 0) {
        Write-Host "`n  Keine Projekte oder Quickstart-Sessions gefunden." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host $bar -ForegroundColor Cyan
    $tokStr = Get-DashTokStr $grandTotal
    Write-Host ("  $count Eintraege  |  $tokStr Token gesamt") -ForegroundColor DarkGray
    Write-Host $bar -ForegroundColor Cyan
    Write-Host ""
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

    zellij delete-session $ProjectName --force 2>$null
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

    # PROJECT_DNA.md anzeigen wenn vorhanden + automatisch extrahieren
    $dnaPath    = Join-Path $projectPath "PROJECT_DNA.md"
    $dnaContent = if (Test-Path $dnaPath) { (Get-Content $dnaPath -Raw -Encoding UTF8).Trim() } else { "" }
    if ($dnaContent) {
        Write-Host "`n=== PROJECT_DNA.md ===" -ForegroundColor Cyan
        Write-Host $dnaContent
        Write-Host "======================`n" -ForegroundColor Cyan
    }

    # Automatische Lektion-Extraktion aus PROJECT_DNA.md
    $newLessons = [System.Collections.Generic.List[string]]::new()
    if ($dnaContent) {
        # Extrahiere alle Zeilen die mit "- " beginnen
        $dnaLines = $dnaContent -split "`n"
        foreach ($line in $dnaLines) {
            if ($line -match '^\s*- (.+)$') {
                $lesson = $matches[1].Trim()
                if ($lesson -and $lesson.Length -gt 5) {
                    $newLessons.Add("[$date] [$ProjectName] $lesson")
                }
            }
        }
    }

    # Zusätzliche manuelle Lektionen
    Write-Host "Weitere Lektionen fuer WORKBENCH_BRAIN.md eingeben (optional):" -ForegroundColor Yellow
    Write-Host "  Format: [tag] Lektion   (z.B. [python] Immer venv vor Start aktivieren)" -ForegroundColor DarkGray
    Write-Host "  Leer lassen + Enter zum Beenden`n" -ForegroundColor DarkGray

    $i = 1
    while ($true) {
        $entry = Read-Host "  Lektion $i (oder Enter um zu überspringen)"
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

    # LESSONS_LEARNED.md Datei im Projektordner erstellen
    $lessonsPath = Join-Path $projectPath "LESSONS_LEARNED.md"
    $lessonsTemplate = Get-Content -Path (Join-Path (Get-LabHome) "templates\LESSONS_LEARNED.md") -Raw -Encoding UTF8
    $lessonsContent = $lessonsTemplate `
        -replace '\[PROJEKTNAME\]', $ProjectName `
        -replace '\[DATUM\]', $date
    $lessonsContent | Out-File $lessonsPath -Encoding UTF8
    Write-Host "LESSONS_LEARNED.md erstellt: $lessonsPath" -ForegroundColor Green
    Write-Host "(Bitte mit deinen Erkenntnissen ausfüllen)" -ForegroundColor DarkGray

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
        zellij delete-session $ProjectName --force 2>$null
        Remove-LabSessionState -SessionName $ProjectName
        Remove-Item -LiteralPath $configPathFile -Force
        Write-Host "Projekt '$ProjectName' abgeschlossen. Ordner: $projectPath" -ForegroundColor Green
    }
}

# === COLLABORATION FUNCTIONS ===

function lab-watch {
    $projPath = Get-LabCurrentProjectPath -SessionName $env:LAB_SESSION_NAME
    if (-not (Test-Path $projPath)) {
        Write-Host "Projektordner nicht gefunden." -ForegroundColor Red
        return
    }

    . (Join-Path $env:LAB_HOME "lab_collab.ps1")
    $jobName = Start-LabWatcher -ProjectPath $projPath
    Write-Host "Collab Watcher gestartet: $jobName" -ForegroundColor Green
}

function lab-locks {
    $projPath = Get-LabCurrentProjectPath -SessionName $env:LAB_SESSION_NAME
    $locksDir = Join-Path $projPath ".lab\state\locks"

    if (-not (Test-Path $locksDir)) {
        Write-Host "Keine Locks vorhanden (oder noch kein Projekt initialisiert)." -ForegroundColor Gray
        return
    }

    $locks = @(Get-ChildItem $locksDir -Filter "*.lock" -ErrorAction SilentlyContinue)
    if ($locks.Count -eq 0) {
        Write-Host "[OK] Keine aktiven Locks." -ForegroundColor Green
        return
    }

    Write-Host "`nAKTIVE LOCKS" -ForegroundColor Yellow
    Write-Host "=============" -ForegroundColor Yellow
    foreach ($lock in $locks) {
        $lockData = Get-Content $lock -Raw -Encoding UTF8 | ConvertFrom-Json
        Write-Host ("  {0,-20} Agent: {1,-10} PID: {2}" -f $lockData.file, $lockData.agent, $lockData.pid) -ForegroundColor Yellow
    }
    Write-Host ""
}

function lab-unlock {
    param ([string]$File)
    if (-not $File) {
        Write-Host "Usage: lab-unlock [MISSION.md|SCRATCHPAD.md|...]" -ForegroundColor Red
        return
    }

    . (Join-Path $env:LAB_HOME "lab_collab.ps1")
    if (Remove-LabFileLock -File $File) {
        Write-Host "Lock entfernt: $File" -ForegroundColor Green
    } else {
        Write-Host "Kein Lock fuer $File vorhanden." -ForegroundColor Yellow
    }
}

function lab-resolve {
    param ([string]$FileName)

    . (Join-Path $env:LAB_HOME "lab_collab.ps1")

    $projPath = Get-LabCurrentProjectPath -SessionName $env:LAB_SESSION_NAME
    $conflictsDir = Join-Path $projPath ".lab\state\conflicts"

    if (-not (Test-Path $conflictsDir)) {
        Write-Host "Keine Konflikt-Verzeichnis. Kein Conflict-Watcher aktiv?" -ForegroundColor Yellow
        return
    }

    if ($FileName) {
        $conflicts = @(Get-ChildItem $conflictsDir -Filter "$FileName.*" -ErrorAction SilentlyContinue)
    } else {
        $conflicts = @(Get-ChildItem $conflictsDir -Filter "*.conflict" -ErrorAction SilentlyContinue)
    }

    if ($conflicts.Count -eq 0) {
        Write-Host "Keine ausstehenden Konflikte fuer '$FileName'." -ForegroundColor Green
        return
    }

    foreach ($conflictFile in $conflicts | Sort-Object LastWriteTime -Descending | Select-Object -First 1) {
        Write-Host ""
        Write-Host "=== CONFLICT RESOLUTION ===" -ForegroundColor Yellow
        Write-Host "File: $($conflictFile.Name)" -ForegroundColor Cyan
        Write-Host ""

        $content = Get-Content $conflictFile -Raw -Encoding UTF8

        $edit1 = ""
        $edit2 = ""

        $lines = $content -split [Environment]::NewLine
        $inEdit1 = $false
        $inEdit2 = $false

        foreach ($line in $lines) {
            if ($line -match "^--- EDIT 1") { $inEdit1 = $true; $inEdit2 = $false; continue }
            if ($line -match "^--- EDIT 2") { $inEdit1 = $false; $inEdit2 = $true; continue }
            if ($inEdit1) { $edit1 += $line + [Environment]::NewLine }
            if ($inEdit2) { $edit2 += $line + [Environment]::NewLine }
        }

        Write-Host "OPTION 1 (Erstes Edit):" -ForegroundColor Cyan
        Write-Host $edit1 -ForegroundColor Gray
        Write-Host ""
        Write-Host "OPTION 2 (Zweites Edit):" -ForegroundColor Cyan
        Write-Host $edit2 -ForegroundColor Gray
        Write-Host ""

        $choice = Read-Host "Waehle Option [1/2]"

        if ($choice -in @("1", "2")) {
            if (Resolve-LabConflict -ConflictFile $conflictFile.FullName -Choice $choice -ProjectPath $projPath) {
                Write-Host "Konflikt geloest!" -ForegroundColor Green
            }
        } else {
            Write-Host "Ungueltige Auswahl." -ForegroundColor Red
        }
    }
}

