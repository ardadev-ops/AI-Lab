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

function Get-ClaudeUsageSummary([string]$path) {
    $claudeRoot = Join-Path $HOME ".claude\projects"
    $projectKey = Get-ClaudeProjectKey $path
    if (-not $projectKey) { return $null }

    $projectDir = Join-Path $claudeRoot $projectKey
    if (-not (Test-Path $projectDir)) { return $null }

    $logFile = Get-ChildItem $projectDir -Filter *.jsonl -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

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
        $usage = Get-ClaudeUsageSummary (Get-CurrentProjectPath)
        if ($usage) {
            $logItem = Get-Item $usage.LogFile
            $parts += @(
                $usage.Input,
                $usage.Output,
                $usage.CacheRead,
                $usage.CacheCreate,
                $usage.WebSearch,
                $usage.WebFetch,
                $usage.Entries,
                $logItem.Length,
                $logItem.LastWriteTimeUtc.Ticks
            )
        } else {
            $parts += "no-claude-usage"
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
        Get-Content $path -Encoding UTF8
    } else {
        Write-Host "Warte auf: $path" -ForegroundColor Yellow
    }
}

function Render-Usage([string]$path) {
    Clear-Host
    $projectPath = Get-CurrentProjectPath
    $usage = Get-ClaudeUsageSummary $projectPath

    Write-Host "USAGE BOARD" -ForegroundColor Cyan
    Write-Host "Pfad: $projectPath" -ForegroundColor DarkGray
    Write-Host "Phase: $(Get-Phase)" -ForegroundColor Gray
    Write-Host ""

    if ($usage) {
        $totalKnown = $usage.Input + $usage.Output + $usage.CacheRead + $usage.CacheCreate
        Write-Host "Claude Tokens" -ForegroundColor Cyan
        Write-Host ("  Input:        {0}" -f $usage.Input)
        Write-Host ("  Output:       {0}" -f $usage.Output)
        Write-Host ("  Cache Read:   {0}" -f $usage.CacheRead)
        Write-Host ("  Cache Create: {0}" -f $usage.CacheCreate)
        Write-Host ("  Total Known:  {0}" -f $totalKnown) -ForegroundColor Green
        Write-Host ("  Requests:     {0} Eintraege | WebSearch {1} | WebFetch {2}" -f $usage.Entries, $usage.WebSearch, $usage.WebFetch) -ForegroundColor DarkGray
    } else {
        Write-Host "Claude Tokens: keine lokale Quelle gefunden." -ForegroundColor Yellow
    }

    Write-Host ""

    if (Test-Path $path) {
        Get-Content $path -Encoding UTF8
    } else {
        Write-Host "Warte auf: $path" -ForegroundColor Yellow
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
