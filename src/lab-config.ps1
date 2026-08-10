# Central Lab Configuration
# Import diese Datei in alle Lab-Scripts mit: . (Join-Path $PSScriptRoot "..\src\lab-config.ps1")

$script:LAB_FILE_NAMES = @{
    Mission     = "MISSION.md"
    Usage       = "USAGE.md"
    Phase       = "PHASE.txt"
    Bootstrap   = "BOOTSTRAP.md"
    DNA         = "PROJECT_DNA.md"
    Scratchpad  = "SCRATCHPAD.md"
    SessionStart = "SESSION_START.txt"
}

# Hilfsfunktion zum Zugriff auf Konfiguration
function Get-LabFileName {
    param([string]$Key)
    if ($script:LAB_FILE_NAMES.ContainsKey($Key)) {
        return $script:LAB_FILE_NAMES[$Key]
    }
    Write-Warning "Unknown file key: $Key"
    return $null
}

Write-Host "[OK] Lab-Config geladen" -ForegroundColor DarkGray
