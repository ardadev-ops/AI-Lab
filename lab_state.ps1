. (Join-Path $PSScriptRoot "lab_paths.ps1")

function Get-LabStateRoot {
    $root = Join-LabPath "state"
    return (Ensure-LabDirectory $root)
}

function Get-LabSessionStateDirectory {
    $dir = Join-Path (Get-LabStateRoot) "sessions"
    return (Ensure-LabDirectory $dir)
}

function Get-LabSessionStatePath {
    param([string]$SessionName)

    if (-not $SessionName) { return $null }
    return (Join-Path (Get-LabSessionStateDirectory) "$SessionName.json")
}

function Set-LabSessionState {
    param(
        [string]$SessionName,
        [string]$ProjectPath,
        [string]$Mode
    )

    if (-not $SessionName -or -not $ProjectPath) { return }

    $state = @{
        SessionName = $SessionName
        ProjectPath = $ProjectPath
        Mode        = $Mode
        UpdatedAt   = (Get-Date).ToString("o")
    }

    $statePath = Get-LabSessionStatePath $SessionName
    $state | ConvertTo-Json | Set-Content -Path $statePath -Encoding UTF8
    $ProjectPath | Out-File (Get-LabLastProjectPathFile) -Force -Encoding UTF8
}

function Get-LabSessionState {
    param([string]$SessionName)

    $statePath = Get-LabSessionStatePath $SessionName
    if (-not $statePath -or -not (Test-Path $statePath)) { return $null }

    try {
        return (Get-Content $statePath -Raw -Encoding UTF8 | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Get-LabCurrentProjectPath {
    param([string]$SessionName)

    if ($env:LAB_PROJECT_PATH -and (Test-Path $env:LAB_PROJECT_PATH)) {
        return $env:LAB_PROJECT_PATH
    }

    if ($SessionName) {
        $state = Get-LabSessionState $SessionName
        if ($state -and $state.ProjectPath -and (Test-Path $state.ProjectPath)) {
            return $state.ProjectPath
        }
    }

    $lastPathFile = Get-LabLastProjectPathFile
    if (Test-Path $lastPathFile) {
        $lastPath = (Get-Content $lastPathFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue).Trim()
        if ($lastPath -and (Test-Path $lastPath)) {
            return $lastPath
        }
    }

    return $null
}

function Get-LabKnownSessionNames {
    $dir = Get-LabSessionStateDirectory
    if (-not (Test-Path $dir)) { return @() }

    return Get-ChildItem $dir -Filter *.json -File -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty BaseName
}

function Remove-LabSessionState {
    param([string]$SessionName)

    $statePath = Get-LabSessionStatePath $SessionName
    if ($statePath -and (Test-Path $statePath)) {
        Remove-Item -LiteralPath $statePath -Force
    }
}
