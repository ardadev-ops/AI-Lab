# LAB COMMANDS — Referenz

## Starten & Initialisieren

| Befehl                  | Was passiert                                                        |
|-------------------------|---------------------------------------------------------------------|
| `init`                  | Laborstruktur im aktuellen Verzeichnis initialisieren                |
| `start-ai`              | Neue freie Session (auto-name: quick-1, quick-2, ...)               |
| `start-ai [Name]`       | Neue freie Session mit eigenem Namen                                |
| `start-ai-join`         | Alle vorhandenen Quickstart-Sessions auflisten                      |
| `start-ai-join [Name]`  | Bestehende Quickstart-Session wieder joinen                         |
| `lab [Name]`            | Projekt öffnen oder neu erstellen                                   |
| `lab [Name] dotnet`     | Projekt mit .NET-Template erstellen                                 |
| `lab [Name] python`     | Projekt mit Python-Template erstellen                               |
| `lab [Name] web`        | Projekt mit Web-Template (HTML/CSS/JS) erstellen                    |
| `setup-workbench.ps1`   | Werkbank auf diesem Rechner installieren                            |

## Projekt verwalten

| Befehl                    | Was passiert                                          |
|---------------------------|-------------------------------------------------------|
| `lab-create [Name]`       | Ordner + Templates anlegen, Zellij NICHT starten      |
| `lab-create [Name] dotnet`| Wie oben, mit .NET-Template                           |
| `lab-join [Name]`         | Bestehende Zellij-Session wieder joinen               |
| `lab-status`              | Alle Projekte mit Phase und letzter Aktivität zeigen  |
| `lab-phase [Phase]`       | Phase wechseln: Brainstorming / Entwicklung / Debugging|
| `lab-open`                | Aktuelles Projektverzeichnis im Explorer öffnen       |
| `lab-report`              | Bericht aus MISSION + DNA + USAGE als .md generieren  |
| `lab-complete [Name]`     | Projekt abschließen: Lektionen → WORKBENCH_BRAIN.md, Abschlussbericht, aus Registry entfernen |
| `lab-delete [Name]`       | Projekt aus der Lab-Registry entfernen                |
| `lab-delete [Name] -DeleteFiles` | Wie oben, Projektordner ebenfalls löschen    |
| `lab-sessions`            | Alle laufenden Zellij-Sessions anzeigen (live)        |
| `lab-kill [Name...]`      | Eine oder mehrere Sessions gezielt beenden            |
| `lab-killall`             | Alle laufenden Sessions auf einmal beenden            |
| `lab-clean`               | Bekannte Lab-Sessions nach Bestätigung beenden        |
| `lab-gc`                  | Orphan-Sessions (kein Lab-State) + stale State-Files bereinigen |
| `lab-switch [Name]`       | Zu einer anderen laufenden Session wechseln           |
| `lab-dashboard`           | Alle Projekte + Quickstarts auf einen Blick (Phase, Token, Status) |
| `lab --kill [Name]`       | Einzelne Session beenden (alt)                        |
| `lab --list`              | Alle registrierten Projekte auflisten                 |

## Automatisch im Hintergrund

| Wann                      | Was passiert automatisch                              |
|---------------------------|-------------------------------------------------------|
| `lab [Name]` (neu)        | Templates kopiert, Projektname in MISSION + USAGE     |
| `lab [Name] [typ]` (neu)  | Zusätzlich Typ-Templates kopiert                      |
| Claude beenden            | USAGE.md bekommt Eintrag mit Datum und Phase          |
| Claude beenden            | Git-Checkpoint: automatischer Commit aller Änderungen |

## Zusammenarbeit & Locks (Claude ↔ Codex)

| Befehl                    | Was passiert                                          |
|---------------------------|-------------------------------------------------------|
| `lab-watch`               | Collab-Watcher manuell starten (überwacht MISSION.md, SCRATCHPAD.md) |
| `lab-locks`               | Alle aktiven Locks anzeigen (Datei-Sperren zwischen Agents) |
| `lab-unlock [File]`       | Lock für eine Datei entfernen (z.B. `lab-unlock MISSION.md`) |
| `lab-resolve [File]`      | Konflikte auflösen (bei gleichzeitigen Edits)        |

## Zellij-Layout (beide Modi)

| Pane           | Inhalt                                                  |
|----------------|---------------------------------------------------------|
| ACTOR_CLAUDE   | Claude Code CLI                                         |
| ACTOR_CODEX    | Codex CLI                                               |
| MISSION        | Live-Ansicht MISSION.md (alle 2 Sek. aktualisiert)      |
| USAGE          | Live-Ansicht USAGE.md (Sessions + Timestamps)           |
| RESEARCH_CHAT  | Gemini — eigenständig, kein Projektkontext              |

## Projekt-Dateien (werden automatisch erstellt)

| Datei            | Zweck                                                   |
|------------------|---------------------------------------------------------|
| `MISSION.md`     | Projektziel + Arbeitsplan (von Claude befüllt)          |
| `USAGE.md`       | Session-Log (automatisch, kein manueller Aufwand)       |
| `PHASE.txt`      | Aktuelle Phase (Brainstorming / Entwicklung / Debugging)|
| `BOOTSTRAP.md`   | Betriebsprotokoll für Claude (Confidence-Score etc.)    |
| `CLAUDE.md`      | Auto-geladen von Claude beim Start                      |
| `PROJECT_DNA.md` | Fehler und Lektionen (von Claude eingetragen)           |
| `SCRATCHPAD.md`  | Übergaben zwischen Claude und Codex                     |
