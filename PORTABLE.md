# Portable Workbench

Diese Werkbank ist jetzt so aufgebaut, dass sie auf einem anderen Laptop oder Server wiederverwendet werden kann.

## Mitnehmen
1. Den ganzen Ordner kopieren oder als Git-Repo klonen.
2. Auf dem Zielsystem `setup-workbench.ps1` ausfuehren.
3. Neues Terminal oeffnen.
4. `start-ai` oder `lab-create` verwenden.

## Wichtig
- `LAB_HOME` zeigt auf den Werkbank-Ordner.
- Layouts liegen in `src/layouts/`.
- Das PowerShell-Profil laedt `src/shell/profile.ps1`.
- Templates liegen in `templates/{base,dotnet,python,web}/`.
- Persoenliche API-Keys und User-Logins bleiben lokal auf dem Zielgeraet.

## Voraussetzungen
- PowerShell
- git
- zellij
- claude
- codex
- gemini
