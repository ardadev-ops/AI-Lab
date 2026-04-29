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
Ensure-LabDirectory (Join-Path (Get-LabStateRoot) "locks") | Out-Null
Ensure-LabDirectory (Join-Path (Get-LabStateRoot) "snapshots") | Out-Null
Ensure-LabDirectory (Join-Path (Get-LabStateRoot) "conflicts") | Out-Null
Ensure-LabDirectory (Join-LabPath "shell") | Out-Null
Ensure-LabDirectory (Join-LabPath "layouts") | Out-Null

[Environment]::SetEnvironmentVariable("LAB_HOME", $LabHome, "User")

# PowerShell-Profil: nur anhängen wenn der Lab-Loader noch nicht drin ist
$profileDir = Split-Path -Parent $PROFILE
Ensure-LabDirectory $profileDir | Out-Null

$loader = @"

# AI Lab Workbench
`$env:LAB_HOME = "$LabHome"
if (Test-Path (Join-Path `$env:LAB_HOME "shell\profile.ps1")) {
    . (Join-Path `$env:LAB_HOME "shell\profile.ps1")
}
"@

$existing = if (Test-Path $PROFILE) { Get-Content $PROFILE -Raw -Encoding UTF8 -ErrorAction SilentlyContinue } else { "" }
if ($existing -notmatch [regex]::Escape($LabHome)) {
    Add-Content -Path $PROFILE -Value $loader -Encoding UTF8
    Write-Host "PowerShell-Profil aktualisiert: $PROFILE" -ForegroundColor Green
} else {
    Write-Host "PowerShell-Profil bereits konfiguriert." -ForegroundColor DarkGray
}

# Machine-spezifische Claude-Berechtigungen generieren
$zellijConfig = Join-Path $HOME ".config\zellij"
$quickstartClaudeDir = Ensure-LabDirectory (Join-Path (Get-LabQuickstartDirectory) ".claude")
$quickstartSettings = @"
{
  "permissions": {
    "allow": [
      "Read($zellijConfig\\layouts\\**)",
      "Read($zellijConfig\\**)",
      "WebSearch"
    ]
  }
}
"@
Set-Content -Path (Join-Path $quickstartClaudeDir "settings.local.json") -Value $quickstartSettings -Encoding UTF8
Write-Host "Claude-Berechtigungen generiert: $quickstartClaudeDir" -ForegroundColor Green

# WORKBENCH_BRAIN.md anlegen wenn noch nicht vorhanden
$brainPath = Join-Path $LabHome "WORKBENCH_BRAIN.md"
if (-not (Test-Path $brainPath)) {
    Set-Content $brainPath -Value "# WORKBENCH BRAIN`nDestillierte Lektionen aus abgeschlossenen Projekten. Max 50 Eintraege, aelteste rotieren raus.`nNur bei Bedarf lesen. Nicht automatisch laden.`n`n---`n" -Encoding UTF8
    Write-Host "WORKBENCH_BRAIN.md angelegt." -ForegroundColor Green
}

# Tool-Check mit Installationshinweisen
Write-Host "`nWorkbench installiert unter: $LabHome" -ForegroundColor Green

$toolInfo = @{
    git    = "https://git-scm.com"
    zellij = "winget install zellij  (oder https://zellij.dev)"
    claude = "npm install -g @anthropic-ai/claude-code"
    codex  = "npm install -g @openai/codex"
    gemini = "npm install -g @google/gemini-cli"
}

Write-Host "`nTool-Status:" -ForegroundColor Cyan
foreach ($tool in $toolInfo.Keys) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ("  [OK]    " + $tool) -ForegroundColor Green
    } else {
        Write-Host ("  [FEHLT] " + $tool + "  →  " + $toolInfo[$tool]) -ForegroundColor Yellow
    }
}

Write-Host "`nNeues Terminal oeffnen und dann 'start-ai' oder 'lab-create [Name]' verwenden." -ForegroundColor Cyan
