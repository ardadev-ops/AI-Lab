# C:\LabEnviorment\goto_project.ps1
. (Join-Path $PSScriptRoot "lab_paths.ps1")
. (Join-Path $PSScriptRoot "lab_state.ps1")

$targetPath = Get-LabCurrentProjectPath -SessionName $env:LAB_SESSION_NAME
if ($targetPath) {
    Set-Location $targetPath
} else {
    Write-Host "Kein aktiver Lab-Pfad gefunden." -ForegroundColor Yellow
}
