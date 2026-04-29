#!/usr/bin/env pwsh
# Test lab_paths.ps1 functions with new directory structure

. ./lab_paths.ps1

Write-Host "`n=== Testing lab_paths.ps1 Functions ===" -ForegroundColor Cyan

# Test 1: Get-LabTemplateDirectory (base)
$basePath = Get-LabTemplateDirectory
Write-Host "`nTest 1: Get-LabTemplateDirectory" -ForegroundColor Yellow
Write-Host "  Result: $basePath"
if (Test-Path $basePath) {
    Write-Host "  Status: [OK] Path exists" -ForegroundColor Green
} else {
    Write-Host "  Status: FAIL - Path does not exist" -ForegroundColor Red
}

# Test 2: Get-LabTemplateDirectory (python)
$pythonPath = Get-LabTemplateDirectory "python"
Write-Host "`nTest 2: Get-LabTemplateDirectory 'python'" -ForegroundColor Yellow
Write-Host "  Result: $pythonPath"
if (Test-Path $pythonPath) {
    Write-Host "  Status: [OK] Path exists" -ForegroundColor Green
} else {
    Write-Host "  Status: FAIL - Path does not exist" -ForegroundColor Red
}

# Test 3: Get-LabLayoutPath
$layoutPath = Get-LabLayoutPath "universal.kdl"
Write-Host "`nTest 3: Get-LabLayoutPath 'universal.kdl'" -ForegroundColor Yellow
Write-Host "  Result: $layoutPath"
if (Test-Path $layoutPath) {
    Write-Host "  Status: [OK] File exists" -ForegroundColor Green
} else {
    Write-Host "  Status: FAIL - File does not exist" -ForegroundColor Red
}

# Test 4: Get-LabShellProfilePath
$profilePath = Get-LabShellProfilePath
Write-Host "`nTest 4: Get-LabShellProfilePath" -ForegroundColor Yellow
Write-Host "  Result: $profilePath"
if (Test-Path $profilePath) {
    Write-Host "  Status: [OK] File exists" -ForegroundColor Green
} else {
    Write-Host "  Status: FAIL - File does not exist" -ForegroundColor Red
}

# Test 5: Verify old paths are gone
Write-Host "`n=== Cleanup Verification ===" -ForegroundColor Cyan
$oldPaths = @(
    "shell",
    "layouts",
    "templates-dotnet",
    "templates-python",
    "templates-web"
)

$allCleaned = $true
foreach ($path in $oldPaths) {
    if (Test-Path $path) {
        Write-Host "  Found: $path [FAIL]" -ForegroundColor Red
        $allCleaned = $false
    } else {
        Write-Host "  Removed: $path [OK]" -ForegroundColor Green
    }
}

if ($allCleaned) {
    Write-Host "`nAll old directories cleaned up [OK]" -ForegroundColor Green
} else {
    Write-Host "`nSome old directories still exist" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
