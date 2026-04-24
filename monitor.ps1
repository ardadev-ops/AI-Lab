param($filename)

function Get-CurrentProjectPath {
    return (Get-Location).Path
}

function Get-Phase {
    $phaseFile = Join-Path (Get-CurrentProjectPath) "PHASE.txt"
    if (Test-Path $phaseFile) {
        return (Get-Content $phaseFile -Raw -Encoding UTF8).Trim()
    }
    return "?"
}

function Get-ClaudeProjectKey([string]$path) {
    if (-not $path) { return $null }
    return ($path -replace '[^A-Za-z0-9]', '-')
}

function Get-Int64Value($value) {
    if ($null -eq $value) { return [int64]0 }
    return [int64]$value
}

function Get-ClaudeLogFile([string]$path) {
    $claudeRoot = Join-Path $HOME ".claude\projects"
    $projectKey = Get-ClaudeProjectKey $path
    if (-not $projectKey) { return $null }
    $projectDir = Join-Path $claudeRoot $projectKey
    if (-not (Test-Path $projectDir)) { return $null }
    return Get-ChildItem $projectDir -Filter *.jsonl -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Get-SessionTokens([string]$projectPath) {
    $logFile = Get-ClaudeLogFile $projectPath
    if (-not $logFile) { return $null }

    $sessionStartFile = Join-Path $projectPath "SESSION_START.txt"
    $sessionStart = $null
    if (Test-Path $sessionStartFile) {
        $raw = (Get-Content $sessionStartFile -Raw -Encoding UTF8).Trim()
        try { $sessionStart = [datetime]::Parse($raw) } catch {}
    }

    $result = @{
        LogFile      = $logFile.FullName
        Input        = [int64]0
        Output       = [int64]0
        CacheRead    = [int64]0
        CacheCreate  = [int64]0
        LastActivity = $null
        Entries      = 0
    }

    foreach ($line in Get-Content $logFile.FullName -Encoding UTF8) {
        try { $entry = $line | ConvertFrom-Json } catch { continue }
        $usage = $entry.message.usage
        if (-not $usage) { continue }

        if ($sessionStart) {
            try {
                $ts = [datetime]::Parse($entry.timestamp)
                if ($ts -lt $sessionStart) { continue }
                if (-not $result.LastActivity -or $ts -gt $result.LastActivity) {
                    $result.LastActivity = $ts
                }
            } catch { continue }
        }

        $result.Input       += Get-Int64Value $usage.input_tokens
        $result.Output      += Get-Int64Value $usage.output_tokens
        $result.CacheRead   += Get-Int64Value $usage.cache_read_input_tokens
        $result.CacheCreate += Get-Int64Value $usage.cache_creation_input_tokens
        $result.Entries     += 1
    }

    return $result
}

function Get-TokenRate([string]$projectPath) {
    $logFile = Get-ClaudeLogFile $projectPath
    if (-not $logFile) { return 0 }

    $cutoff = (Get-Date).AddMinutes(-5)
    $total = [int64]0

    foreach ($line in Get-Content $logFile.FullName -Encoding UTF8) {
        try { $entry = $line | ConvertFrom-Json } catch { continue }
        $usage = $entry.message.usage
        if (-not $usage) { continue }
        try {
            $ts = [datetime]::Parse($entry.timestamp)
            if ($ts -lt $cutoff) { continue }
        } catch { continue }
        $total += Get-Int64Value $usage.input_tokens
        $total += Get-Int64Value $usage.output_tokens
        $total += Get-Int64Value $usage.cache_read_input_tokens
        $total += Get-Int64Value $usage.cache_creation_input_tokens
    }

    return $total
}

function Get-ClaudeUsageSummary([string]$path) {
    $logFile = Get-ClaudeLogFile $path
    if (-not $logFile) { return $null }

    $summary = @{
        LogFile     = $logFile.FullName
        Input       = 0
        Output      = 0
        CacheRead   = 0
        CacheCreate = 0
        WebSearch   = 0
        WebFetch    = 0
        Entries     = 0
    }

    foreach ($line in Get-Content $logFile.FullName -Encoding UTF8) {
        try {
            $entry = $line | ConvertFrom-Json
        } catch {
            continue
        }

        $usage = $entry.message.usage
        if (-not $usage) { continue }

        $summary.Input += Get-Int64Value $usage.input_tokens
        $summary.Output += Get-Int64Value $usage.output_tokens
        $summary.CacheRead += Get-Int64Value $usage.cache_read_input_tokens
        $summary.CacheCreate += Get-Int64Value $usage.cache_creation_input_tokens
        $summary.WebSearch += Get-Int64Value $usage.server_tool_use.web_search_requests
        $summary.WebFetch += Get-Int64Value $usage.server_tool_use.web_fetch_requests
        $summary.Entries += 1
    }

    return $summary
}

function Get-StateSignature([string]$path, [string]$panelFile) {
    $parts = @(
        (Get-CurrentProjectPath),
        (Get-Phase)
    )

    if (Test-Path $path) {
        $item = Get-Item $path
        $parts += @($item.Length, $item.LastWriteTimeUtc.Ticks)
    } else {
        $parts += "missing"
    }

    if ($panelFile -eq "USAGE.md") {
        $pp = Get-CurrentProjectPath
        $logFile = Get-ClaudeLogFile $pp
        if ($logFile) {
            $logItem = Get-Item $logFile.FullName
            $parts += @($logItem.Length, $logItem.LastWriteTimeUtc.Ticks)
        } else {
            $parts += "no-claude-log"
        }
        $ssFile = Join-Path $pp "SESSION_START.txt"
        if (Test-Path $ssFile) {
            $ssItem = Get-Item $ssFile
            $parts += $ssItem.LastWriteTimeUtc.Ticks
        } else {
            $parts += "no-session-start"
        }
    }

    return ($parts -join "|")
}

function Render-Mission([string]$path) {
    Clear-Host
    Write-Host "MISSION BOARD" -ForegroundColor Cyan
    Write-Host "Pfad: $(Get-CurrentProjectPath)" -ForegroundColor DarkGray
    Write-Host "Phase: $(Get-Phase)" -ForegroundColor Gray
    Write-Host "Legende: [ ] Offen  [~] In Arbeit  [x] Erledigt" -ForegroundColor DarkGray
    Write-Host ""

    if (Test-Path $path) {
        foreach ($line in Get-Content $path -Encoding UTF8) {
            if ($line -match '^\s*- \[x\]') {
                Write-Host $line -ForegroundColor Green
            } elseif ($line -match '^\s*- \[~\]') {
                Write-Host $line -ForegroundColor Yellow
            } elseif ($line -match '^\s*- \[ \]') {
                Write-Host $line -ForegroundColor Gray
            } elseif ($line -match '^## ') {
                Write-Host $line -ForegroundColor Cyan
            } else {
                Write-Host $line -ForegroundColor White
            }
        }
    } else {
        Write-Host "Warte auf: $path" -ForegroundColor Yellow
    }
}

function Render-Usage([string]$path) {
    Clear-Host
    $projectPath = Get-CurrentProjectPath
    $sessionName = Split-Path $projectPath -Leaf
    $phase = Get-Phase

    $sessionStartFile = Join-Path $projectPath "SESSION_START.txt"
    $sinceStr = "?"
    if (Test-Path $sessionStartFile) {
        $raw = (Get-Content $sessionStartFile -Raw -Encoding UTF8).Trim()
        try { $sinceStr = ([datetime]::Parse($raw)).ToString("HH:mm") } catch {}
    }

    Write-Host ("TOKEN MANAGER  |  {0}  |  Phase: {1}" -f $sessionName, $phase) -ForegroundColor Cyan
    Write-Host ("Seit: {0}" -f $sinceStr) -ForegroundColor Gray
    Write-Host ""

    $tokens = Get-SessionTokens $projectPath
    if ($tokens -and $tokens.Entries -gt 0) {
        $total     = $tokens.Input + $tokens.Output + $tokens.CacheRead + $tokens.CacheCreate
        $cache     = $tokens.CacheRead + $tokens.CacheCreate
        $inputK    = "{0:N1}k" -f ($tokens.Input  / 1000)
        $outputK   = "{0:N1}k" -f ($tokens.Output / 1000)
        $totalFmt  = if ($total -ge 1000) { "{0:N0}" -f $total } else { "$total" }
        $cacheFmt  = if ($cache -ge 1000) { "{0:N0}" -f $cache } else { "$cache" }

        $rate      = Get-TokenRate $projectPath
        $rateK     = "{0:N1}k" -f ($rate / 1000)

        if ($rate -lt 500) {
            $statusText  = "[ NIEDRIG ]"
            $statusColor = "Green"
        } elseif ($rate -le 3000) {
            $statusText  = "[ MITTEL ]"
            $statusColor = "Yellow"
        } else {
            $statusText  = "[ HOCH ]"
            $statusColor = "Red"
        }

        $lastActStr = "?"
        if ($tokens.LastActivity) {
            $lastActStr = $tokens.LastActivity.ToString("HH:mm")
        }

        Write-Host ("Tokens:  {0,8}   Input: {1} / Output: {2}" -f $totalFmt, $inputK, $outputK)
        Write-Host ("Cache:   {0,8}   gespart" -f $cacheFmt) -ForegroundColor DarkGray
        Write-Host ("Rate:    {0,8} / 5min" -f $rateK)
        Write-Host -NoNewline "Status:  "
        Write-Host $statusText -ForegroundColor $statusColor
        Write-Host ""
        Write-Host ("Letzte Aktivitaet: {0}" -f $lastActStr) -ForegroundColor DarkGray
    } else {
        Write-Host "Keine Session-Daten gefunden." -ForegroundColor Yellow
        Write-Host "Starte eine neue Session mit 'start-ai' oder 'lab [Name]'." -ForegroundColor DarkGray
    }
}

$lastSignature = $null

while ($true) {
    $currentPath = Join-Path (Get-CurrentProjectPath) $filename
    $signature = Get-StateSignature -path $currentPath -panelFile $filename

    if ($signature -ne $lastSignature) {
        if ($filename -eq "MISSION.md") {
            Render-Mission $currentPath
        } elseif ($filename -eq "USAGE.md") {
            Render-Usage $currentPath
        } else {
            Clear-Host
            Write-Host "Pfad: $(Get-CurrentProjectPath)" -ForegroundColor Gray
            if (Test-Path $currentPath) {
                Get-Content $currentPath -Encoding UTF8
            } else {
                Write-Host "Warte auf: $currentPath" -ForegroundColor Yellow
            }
        }

        $lastSignature = $signature
    }

    Start-Sleep 2
}
