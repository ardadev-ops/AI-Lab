. (Join-Path $PSScriptRoot "lab_paths.ps1")
. (Join-Path $PSScriptRoot "lab_state.ps1")

param ([string]$Action, [string]$Typ)

# 1. Spezialbefehle
if ($Action -eq "--list") { Get-ChildItem (Join-Path (Get-LabProjectsDirectory) "*.path") | ForEach-Object { $_.BaseName }; return }
if ($Action -eq "--kill") { zellij delete-session $Typ 2>$null; Write-Host "Session $Typ beendet."; return }

# 2. Projekt Setup
$Target = $Action
$configFolder = Ensure-LabDirectory (Get-LabProjectsDirectory)
$configPathFile = "$configFolder\$Target.path"

if (!(Test-Path $configPathFile)) {
    $baseDir = Read-Host "Projekt '$Target' nicht gefunden. Wo soll der Hauptordner liegen?"
    $fullPath = Join-Path $baseDir $Target
    New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
    $fullPath | Out-File -FilePath $configPathFile -Encoding UTF8
}

$root = (Get-Content $configPathFile).Trim()

# 3. TEMPLATES KOPIEREN (Basis)
$templateSource = Get-LabTemplateDirectory
if (Test-Path $templateSource) {
    Get-ChildItem $templateSource | ForEach-Object {
        $dest = Join-Path $root $_.Name
        if (!(Test-Path $dest)) {
            Copy-Item $_.FullName -Destination $dest -Recurse
            Write-Host "Template: $($_.Name)" -ForegroundColor Green
        }
    }
    # Projektnamen einsetzen
    foreach ($file in @("MISSION.md", "USAGE.md")) {
        $filePath = Join-Path $root $file
        if (Test-Path $filePath) {
            (Get-Content $filePath -Raw -Encoding UTF8) -replace '\[PROJEKTNAME\]', $Target |
                Set-Content $filePath -Encoding UTF8 -NoNewline
        }
    }
}

# 4. TYP-SPEZIFISCHE TEMPLATES (dotnet / python / web)
if ($Typ) {
    $typeSource = Get-LabTemplateDirectory $Typ
    if (Test-Path $typeSource) {
        Copy-Item -Path "$typeSource\*" -Destination $root -Recurse -Force
        Write-Host "Typ-Template '$Typ' angewendet." -ForegroundColor Cyan
    } else {
        Write-Host "Kein Template fuer Typ '$Typ'. Verfuegbar: dotnet, python, web" -ForegroundColor Yellow
    }
}

# 5. Zellij Session starten
$env:LAB_PROJECT_PATH = $root
$env:LAB_SESSION_NAME = $Target
if (-not $env:LAB_HOME) { $env:LAB_HOME = Get-LabHome }
Set-LabSessionState -SessionName $Target -ProjectPath $root -Mode "project"
(Get-Date -Format "o") | Set-Content (Join-Path $root "SESSION_START.txt") -Encoding UTF8
Set-Location $root
zellij --layout (Get-LabLayoutPath "universal.kdl")
