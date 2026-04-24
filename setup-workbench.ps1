param(
    [string]$LabHome = $PSScriptRoot
)

$LabHome = (Resolve-Path $LabHome).Path
$env:LAB_HOME = $LabHome

. (Join-Path $LabHome "lab_paths.ps1")
. (Join-Path $LabHome "lab_state.ps1")

Ensure-LabDirectory (Get-LabProjectsDirectory) | Out-Null
Ensure-LabDirectory (Get-LabQuickstartDirectory) | Out-Null
Ensure-LabDirectory (Get-LabStateRoot) | Out-Null
Ensure-LabDirectory (Get-LabSessionStateDirectory) | Out-Null
Ensure-LabDirectory (Join-LabPath "shell") | Out-Null
Ensure-LabDirectory (Join-LabPath "layouts") | Out-Null

[Environment]::SetEnvironmentVariable("LAB_HOME", $LabHome, "User")

$profileDir = Split-Path -Parent $PROFILE
Ensure-LabDirectory $profileDir | Out-Null

$loader = @"
`$env:LAB_HOME = "$LabHome"
if (Test-Path (Join-Path `$env:LAB_HOME "shell\profile.ps1")) {
    . (Join-Path `$env:LAB_HOME "shell\profile.ps1")
}
"@

Set-Content -Path $PROFILE -Value $loader -Encoding UTF8

$tools = @("git", "zellij", "claude", "codex", "gemini")
Write-Host "Workbench installiert unter: $LabHome" -ForegroundColor Green
Write-Host "PowerShell-Profil aktualisiert: $PROFILE" -ForegroundColor Green

foreach ($tool in $tools) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ("[OK] " + $tool) -ForegroundColor Green
    } else {
        Write-Host ("[FEHLT] " + $tool) -ForegroundColor Yellow
    }
}

Write-Host "Neues Terminal oeffnen und dann start-ai oder lab-create verwenden." -ForegroundColor Cyan
