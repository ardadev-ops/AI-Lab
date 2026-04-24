function Get-LabHome {
    if ($env:LAB_HOME -and (Test-Path $env:LAB_HOME)) {
        return $env:LAB_HOME
    }

    return $PSScriptRoot
}

function Join-LabPath {
    param([string]$RelativePath)

    if (-not $RelativePath) {
        return (Get-LabHome)
    }

    return (Join-Path (Get-LabHome) $RelativePath)
}

function Get-LabProjectsDirectory {
    return (Join-LabPath "projects")
}

function Get-LabQuickstartDirectory {
    return (Join-LabPath "quickstart")
}

function Get-LabTemplateDirectory {
    param([string]$Type)

    if ($Type) {
        return (Join-LabPath ("templates-" + $Type))
    }

    return (Join-LabPath "templates")
}

function Get-LabLayoutPath {
    param([string]$LayoutName)

    return (Join-LabPath (Join-Path "layouts" $LayoutName))
}

function Get-LabLastProjectPathFile {
    return (Join-LabPath "last_project_path.txt")
}

function Get-LabShellProfilePath {
    return (Join-LabPath (Join-Path "shell" "profile.ps1"))
}

function Ensure-LabDirectory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }

    return $Path
}
