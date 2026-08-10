# Lab Collaboration Module: File Locking, Snapshots, Conflict Detection
# Exports: Set-LabFileLock, Remove-LabFileLock, Test-LabFileLocked,
#          Save-LabSnapshot, Register-LabConflict, Get-LabConflicts,
#          Resolve-LabConflict, Start-LabWatcher

. (Join-Path $PSScriptRoot "lab_paths.ps1")

# === LOCK FUNCTIONS ===

function Set-LabFileLock {
    param (
        [Parameter(Mandatory = $true)][string]$File,
        [Parameter(Mandatory = $true)][string]$Agent
    )
    $locksDir = Ensure-LabDirectory (Get-LabLockDirectory)
    $lockFile = Join-Path $locksDir "$([System.IO.Path]::GetFileName($File)).lock"

    if (Test-Path $lockFile) {
        return $false
    }

    $lockData = @{
        agent     = $Agent
        file      = [System.IO.Path]::GetFileName($File)
        timestamp = (Get-Date -Format "o")
        pid       = $PID
    } | ConvertTo-Json

    $lockData | Set-Content -Path $lockFile -Encoding UTF8 -Force
    return $true
}

function Remove-LabFileLock {
    param (
        [Parameter(Mandatory = $true)][string]$File
    )
    $locksDir = Get-LabLockDirectory
    $lockFile = Join-Path $locksDir "$([System.IO.Path]::GetFileName($File)).lock"

    if (Test-Path $lockFile) {
        Remove-Item -Path $lockFile -Force -ErrorAction SilentlyContinue
        return $true
    }
    return $false
}

function Test-LabFileLocked {
    param (
        [Parameter(Mandatory = $true)][string]$File
    )
    $locksDir = Get-LabLockDirectory
    $lockFile = Join-Path $locksDir "$([System.IO.Path]::GetFileName($File)).lock"

    if (Test-Path $lockFile) {
        try {
            $lockData = Get-Content -Path $lockFile -Raw -Encoding UTF8 | ConvertFrom-Json
            return $lockData
        } catch {
            return $null
        }
    }
    return $null
}

# === SNAPSHOT FUNCTIONS ===

function Save-LabSnapshot {
    param (
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$Agent
    )
    $snapshotsDir = Ensure-LabDirectory (Get-LabSnapshotDirectory)
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    $timestamp = Get-Date -Format "o" -Millisecond ((Get-Date).Millisecond)
    $safeTimestamp = ($timestamp -replace '[:\-\.]', '_')
    $snapshotFile = Join-Path $snapshotsDir "$fileName.$safeTimestamp.snapshot"

    if (Test-Path $FilePath) {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $header = "=== SNAPSHOT $fileName @ $timestamp by $Agent ===" + [Environment]::NewLine
        ($header + $content) | Set-Content -Path $snapshotFile -Encoding UTF8 -Force
        return $snapshotFile
    }
    return $null
}

function Get-LabSnapshot {
    param (
        [Parameter(Mandatory = $true)][string]$SnapshotFile
    )
    if (Test-Path $SnapshotFile) {
        $content = Get-Content -Path $SnapshotFile -Raw -Encoding UTF8
        $headerEnd = $content.IndexOf([Environment]::NewLine)
        if ($headerEnd -gt 0) {
            return $content.Substring($headerEnd + [Environment]::NewLine.Length)
        }
    }
    return $null
}

# === CONFLICT FUNCTIONS ===

function Register-LabConflict {
    param (
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$SnapshotBefore,
        [Parameter(Mandatory = $true)][string]$ContentAfter1,
        [Parameter(Mandatory = $true)][string]$Time1,
        [Parameter(Mandatory = $true)][string]$ContentAfter2,
        [Parameter(Mandatory = $true)][string]$Time2
    )

    $conflictsDir = Ensure-LabDirectory (Get-LabConflictDirectory)
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    $timestamp = (Get-Date -Format "o") -replace '[:\-\.]', '_'
    $conflictFile = Join-Path $conflictsDir "$fileName.$timestamp.conflict"

    $conflictData = @"
=== CONFLICT $fileName ===
TIMESTAMP_DETECTED: $(Get-Date -Format "o")
FILE: $FilePath
STATUS: PENDING

SNAPSHOT_BEFORE:
$(Get-Content $SnapshotBefore -Raw -Encoding UTF8)

--- EDIT 1 (detected at $Time1) ---
$ContentAfter1

--- EDIT 2 (detected at $Time2) ---
$ContentAfter2
"@

    $conflictData | Set-Content -Path $conflictFile -Encoding UTF8 -Force
    return $conflictFile
}

function Get-LabConflicts {
    param (
        [string]$ProjectPath = $env:LAB_PROJECT_PATH
    )
    $conflictsDir = Get-LabConflictDirectory -ProjectPath $ProjectPath
    if (-not $conflictsDir -or -not (Test-Path $conflictsDir)) { return @() }

    Get-ChildItem -Path $conflictsDir -Filter "*.conflict" -ErrorAction SilentlyContinue |
        Where-Object { $_ -match "\.conflict$" }
}

function Resolve-LabConflict {
    param (
        [Parameter(Mandatory = $true)][string]$ConflictFile,
        [Parameter(Mandatory = $true)][string]$Choice,  # "1" or "2" for which version to keep
        [string]$ProjectPath = $env:LAB_PROJECT_PATH
    )

    if (-not (Test-Path $ConflictFile)) {
        Write-Error "Conflict file not found: $ConflictFile"
        return $false
    }

    $conflictContent = Get-Content -Path $ConflictFile -Raw -Encoding UTF8

    # Extract file name from conflict file
    if ($conflictContent -match "^=== CONFLICT (.+?) ===$") {
        $fileName = $matches[1]
    } else {
        Write-Error "Invalid conflict file format"
        return $false
    }

    $targetFile = Join-Path $ProjectPath $fileName

    # Parse the two edits
    if ($conflictContent -match "--- EDIT 1 .+?\n([\s\S]+?)\n--- EDIT 2") {
        $content1 = $matches[1]
    }
    if ($conflictContent -match "--- EDIT 2 .+?\n([\s\S]+?)$") {
        $content2 = $matches[1]
    }

    # Apply chosen version
    if ($Choice -eq "1" -and $content1) {
        $content1 | Set-Content -Path $targetFile -Encoding UTF8 -Force
    } elseif ($Choice -eq "2" -and $content2) {
        $content2 | Set-Content -Path $targetFile -Encoding UTF8 -Force
    } else {
        Write-Error "Invalid choice or content not found"
        return $false
    }

    # Mark as resolved
    $resolvedContent = $conflictContent -replace "STATUS: PENDING", "STATUS: RESOLVED"
    $resolvedFile = $ConflictFile -replace "\.conflict$", ".resolved"
    $resolvedContent | Set-Content -Path $resolvedFile -Encoding UTF8 -Force

    Remove-Item -Path $ConflictFile -Force -ErrorAction SilentlyContinue
    Write-Host "Conflict resolved: $fileName (accepted version $Choice)" -ForegroundColor Green
    return $true
}

# === WATCHER FUNCTION ===

function Start-LabWatcher {
    param (
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [int]$IntervalMs = 1000,
        [array]$WatchFiles = @("MISSION.md", "SCRATCHPAD.md")
    )

    $scriptBlock = {
        param($ProjPath, $Interval, $Files)

        . (Join-Path $env:LAB_HOME "lab_paths.ps1")
        . (Join-Path $env:LAB_HOME "lab_collab.ps1")

        $fileStates = @{}

        while ($true) {
            try {
                foreach ($file in $Files) {
                    $filePath = Join-Path $ProjPath $file
                    if (-not (Test-Path $filePath)) { continue }

                    $currentContent = Get-Content -Path $filePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                    $currentHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                        [System.Text.Encoding]::UTF8.GetBytes($currentContent)
                    ) | ForEach-Object { $_.ToString("x2") } | Join-String

                    if (-not $fileStates.ContainsKey($file)) {
                        $fileStates[$file] = @{ hash = $currentHash; time = Get-Date; snapshot = $null }
                    } else {
                        $prevState = $fileStates[$file]
                        if ($prevState.hash -ne $currentHash) {
                            $timeDiff = (Get-Date) - $prevState.time

                            # Conflict detection: if change within 2 seconds of last change
                            if ($timeDiff.TotalSeconds -lt 2 -and $prevState.snapshot) {
                                $snapshotContent = Get-LabSnapshot -SnapshotFile $prevState.snapshot
                                Register-LabConflict -FilePath $filePath `
                                    -SnapshotBefore $prevState.snapshot `
                                    -ContentAfter1 $snapshotContent `
                                    -Time1 $prevState.time.ToString("o") `
                                    -ContentAfter2 $currentContent `
                                    -Time2 (Get-Date).ToString("o")
                            }

                            $snapshot = Save-LabSnapshot -FilePath $filePath -Agent "Watcher"
                            $fileStates[$file] = @{ hash = $currentHash; time = Get-Date; snapshot = $snapshot }
                        }
                    }
                }
                Start-Sleep -Milliseconds $Interval
            } catch {
                # Silent catch — watcher keeps running on errors
            }
        }
    }

    $jobName = "lab-watcher-$(Split-Path -Leaf $ProjectPath)"
    Start-Job -ScriptBlock $scriptBlock -ArgumentList $ProjectPath, $IntervalMs, $WatchFiles -Name $jobName
    return $jobName
}

function Stop-LabWatcher {
    param (
        [string]$SessionName
    )
    $jobName = "lab-watcher-$SessionName"
    Stop-Job -Name $jobName -ErrorAction SilentlyContinue
    Remove-Job -Name $jobName -ErrorAction SilentlyContinue
}

# === HELPER FUNCTIONS (Path management) ===

function Get-LabLockDirectory {
    param([string]$ProjectPath)
    $stateDir = Get-LabStateDirectory -ProjectPath $ProjectPath
    if (-not $stateDir) { return $null }
    return Join-Path $stateDir "locks"
}

function Get-LabSnapshotDirectory {
    param([string]$ProjectPath)
    $stateDir = Get-LabStateDirectory -ProjectPath $ProjectPath
    if (-not $stateDir) { return $null }
    return Join-Path $stateDir "snapshots"
}

function Get-LabConflictDirectory {
    param([string]$ProjectPath)
    $stateDir = Get-LabStateDirectory -ProjectPath $ProjectPath
    if (-not $stateDir) { return $null }
    return Join-Path $stateDir "conflicts"
}

function Get-LabStateDirectory {
    param([string]$ProjectPath)

    if (-not $ProjectPath) { $ProjectPath = $env:LAB_PROJECT_PATH }
    if (-not $ProjectPath) { $ProjectPath = (Get-Location).Path }
    if (-not $ProjectPath) { return $null }

    return Join-Path $ProjectPath ".lab\state"
}
