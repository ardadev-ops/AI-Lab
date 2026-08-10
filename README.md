# AI-Lab — KI-gestützte Entwicklungsumgebung

**Autor:** Alkan Arda  
**Repository:** https://github.com/itzEnemy-dot/AI-Lab  
**Sprache:** PowerShell  

---

## Was ist AI-Lab?

AI-Lab ist eine vollständige, KI-gestützte Entwicklungsarbeitsbank (Workbench), die mehrere KI-Agenten in einer einheitlichen Terminal-Umgebung kombiniert. Das Ziel ist es, Entwicklungsprojekte effizienter zu gestalten, indem KI-Modelle als aktive Mitarbeiter direkt in den Entwicklungs-Workflow eingebunden werden.

Das System arbeitet mit **drei KI-Agenten** gleichzeitig:

| Agent | Rolle |
|-------|-------|
| **Claude Code** | Aktiver Coding-Agent — schreibt, refaktoriert und debuggt Code |
| **Codex (OpenAI)** | Aktiver Coding-Agent — übernimmt Aufgaben parallel oder sequenziell |
| **Gemini** | Passiver Monitor — liest nur mit, gibt Kontext und Überblick |

---

## Wie ist es aufgebaut?

```
AI-Lab/
├── lab.ps1                  # Hauptsteuerskript — Projekte erstellen und starten
├── monitor.ps1              # Echtzeit-Monitor für Token-Verbrauch und Projektstatus
├── setup-workbench.ps1      # Einmaliges Installations-Skript
├── COMMANDS.md              # Befehlsreferenz
├── WORKBENCH_BRAIN.md       # Destillierte Lektionen aus abgeschlossenen Projekten
├── PORTABLE.md              # Anleitung zur Portierung auf andere Systeme
├── src/
│   ├── lab-config.ps1       # Zentrale Konfiguration (Dateinamen, Helper)
│   ├── layouts/             # Zellij-Terminal-Layouts (universal.kdl, quick.kdl)
│   └── shell/
│       └── profile.ps1      # PowerShell-Profil mit allen Befehlen
├── projects/                # Registrierte Projekte (Pfad-Registry)
├── quickstart/              # Freie Sessions ohne Projektbindung
├── templates/
│   ├── base/                # Basis-Template für alle Projekte
│   ├── dotnet/              # .NET-Projekt-Template (Template.csproj + src/)
│   ├── python/              # Python-Projekt-Template (src/main.py)
│   └── web/                 # HTML/CSS/JS-Projekt-Template (index.html + src/)
├── state/                   # Laufzeit-Zustand (Session-Registry)
└── docs/                    # Spezifikationen und Dokumentation
```

### Technologie-Stack

- **PowerShell** — 98.5 % des Codes (Steuerlogik, Automatisierung, Profile)
- **Zellij** — Terminal-Multiplexer (ersetzt tmux), verwaltet Panel-Layouts
- **KDL** — Layout-Konfigurationen für Zellij (1.5 %)

---

## Was macht es genau?

### 1. Projektmanagement
Jedes Projekt bekommt ein eigenes Verzeichnis mit vorgefertigten Konfigurationsdateien:

- `MISSION.md` — Lebendiger Arbeitsplan mit Aufgaben-Status
- `PHASE.txt` — Aktuelle Entwicklungsphase (Brainstorming / Development / Debugging)
- `PROJECT_DNA.md` — Fehler und Lektionen aus dem Projekt
- `SCRATCHPAD.md` — Übergabe-Protokoll zwischen Claude und Codex

### 2. KI-Koordination
Die KI-Agenten kommunizieren über Textdateien. Claude schreibt Ergebnisse in `SCRATCHPAD.md`, Codex liest sie und übernimmt die nächste Aufgabe. Gemini überwacht den Fortschritt passiv.

### 3. Echtzeit-Monitoring
`monitor.ps1` zeigt in Echtzeit:
- Token-Verbrauch (Input, Output, Cache)
- Verbrauchsrate der letzten 5 Minuten
- Projektstatus und aktive Phase
- Aufgaben-Liste aus `MISSION.md` mit Farbkodierung

### 4. Portabilität
Die gesamte Workbench lässt sich auf einen anderen Computer kopieren. API-Keys verbleiben lokal und werden nicht synchronisiert.

---

## Systemvoraussetzungen

Folgende Tools müssen installiert sein:

| Tool | Zweck |
|------|-------|
| **PowerShell** | Shell und Steuerlogik |
| **Git** | Versionskontrolle |
| **Zellij** | Terminal-Multiplexer |
| **Claude** (Anthropic CLI) | KI-Agent 1 |
| **Codex** (OpenAI CLI) | KI-Agent 2 |
| **Gemini** (Google CLI) | KI-Monitor |

> **Hinweis (Windows):** Zellij läuft nativ nur auf Linux/macOS. Auf Windows muss es
> unter **WSL** installiert und von dort gestartet werden — die Layouts öffnen dann
> `powershell.exe` für die Panes. Die PowerShell-Skripte selbst funktionieren auf
> Windows und WSL gleichermaßen.

---

## Installation

```powershell
# 1. Repository klonen
git clone https://github.com/itzEnemy-dot/AI-Lab.git
cd AI-Lab

# 2. Workbench einrichten (einmalig)
.\setup-workbench.ps1

# 3. Neues Terminal öffnen — Befehle sind jetzt verfügbar
```

Das Installationsskript führt automatisch aus:
- Erstellt alle benötigten Verzeichnisse (`projects/`, `quickstart/`, `state/`, `layouts/`)
- Setzt die Umgebungsvariable `LAB_HOME`
- Bindet `shell/profile.ps1` in das PowerShell-Profil ein
- Konfiguriert Claude-Berechtigungen
- Erstellt `WORKBENCH_BRAIN.md`
- Prüft alle Abhängigkeiten und zeigt fehlende Tools an

---

## Handbuch — Alle Befehle im Detail

### Sessions starten

| Befehl | Beschreibung |
|--------|-------------|
| `start-ai` | Startet eine neue freie Session mit automatisch generiertem Namen |
| `start-ai [Name]` | Startet eine neue freie Session mit eigenem Namen |
| `start-ai-join` | Listet alle vorhandenen Quickstart-Sessions auf |
| `start-ai-join [Name]` | Tritt einer vorhandenen Quickstart-Session wieder bei |

**Beispiel:**
```powershell
start-ai MeinProjekt
# Öffnet Zellij mit Claude, Codex und Gemini in getrennten Panels
```

---

### Projekte verwalten

| Befehl | Beschreibung |
|--------|-------------|
| `lab [Name]` | Öffnet ein bestehendes Projekt oder erstellt ein neues (Standard-Template) |
| `lab [Name] dotnet` | Erstellt Projekt mit .NET-Template |
| `lab [Name] python` | Erstellt Projekt mit Python-Template |
| `lab [Name] web` | Erstellt Projekt mit HTML/CSS/JS-Template |
| `lab --list` | Listet alle registrierten Projekte auf |

**Beispiel:**
```powershell
lab MeineWebApp web
# Erstellt Projektordner mit HTML/CSS/JS-Template und startet die Session
```

---

### Projekt-Lifecycle

| Befehl | Beschreibung |
|--------|-------------|
| `lab-create [Name]` | Erstellt Ordner und Templates, ohne Zellij zu starten |
| `lab-create [Name] dotnet` | Wie oben, mit .NET-Template |
| `lab-join [Name]` | Tritt einer laufenden Zellij-Session wieder bei |
| `lab-status` | Zeigt alle Projekte mit Phase und letzter Aktivität |
| `lab-phase [Phase]` | Wechselt die Entwicklungsphase des aktuellen Projekts |
| `lab-open` | Öffnet das aktuelle Projektverzeichnis im Explorer |
| `lab-report` | Generiert einen Markdown-Bericht aus den Projektdateien |
| `lab-complete [Name]` | Schließt ein Projekt ab und erstellt einen Abschlussbericht |
| `lab-delete [Name]` | Entfernt ein Projekt aus der Registry (Dateien bleiben) |
| `lab-delete [Name] -DeleteFiles` | Entfernt Projekt und löscht alle Dateien |

**Beispiel:**
```powershell
lab-phase Development
# Setzt PHASE.txt auf "Development" — KI-Agenten passen ihr Verhalten an
```

---

### Session-Verwaltung

| Befehl | Beschreibung |
|--------|-------------|
| `lab-sessions` | Zeigt alle laufenden Zellij-Sessions |
| `lab-kill [Name]` | Beendet eine bestimmte Session |
| `lab-killall` | Beendet alle Sessions |
| `lab-clean` | Beendet alle bekannten Lab-Sessions nach Bestätigung |

---

### Entwicklungsphasen

Das System kennt drei Phasen, die das Verhalten der KI-Agenten steuern:

| Phase | Verhalten der KI |
|-------|-----------------|
| `Brainstorming` | Ideen entwickeln, keine fertigen Implementierungen |
| `Development` | Code schreiben, alle Dateien unter `./src/` |
| `Debugging` | Fehler minimal fixen, `PROJECT_DNA.md` konsultieren |

```powershell
lab-phase Brainstorming   # Ideen-Phase
lab-phase Development     # Implementierungs-Phase
lab-phase Debugging       # Fehlersuche-Phase
```

---

### Monitor

```powershell
# Im Projektverzeichnis ausführen
.\monitor.ps1
```

Der Monitor zeigt zwei Ansichten (wechselt automatisch):

**MISSION.md-Ansicht:**
- Aufgabenliste mit Farbkodierung
  - Grün: Erledigt `[x]`
  - Gelb: In Arbeit `[~]`
  - Grau: Ausstehend `[ ]`

**USAGE.md-Ansicht — Token-Verbrauch:**
- Eingabe- und Ausgabe-Token
- Cache-Token (gespart/erstellt)
- Verbrauchsrate der letzten 5 Minuten
  - Grün: < 500 Token/5min (niedrig)
  - Gelb: 500–3000 Token/5min (mittel)
  - Rot: > 3000 Token/5min (hoch)

---

### Auf einen anderen Computer portieren

```powershell
# Option A: Git-Klon
git clone https://github.com/itzEnemy-dot/AI-Lab.git
cd AI-Lab
.\setup-workbench.ps1

# Option B: Ordner kopieren
# Den gesamten AI-Lab-Ordner auf den Zielcomputer kopieren
# Dann:
.\setup-workbench.ps1
```

**Wichtig:** API-Keys für Claude, Codex und Gemini müssen auf dem Zielgerät neu konfiguriert werden. Sie werden nicht mit dem Repository synchronisiert.

---

## Typischer Workflow

```
1. lab MeinProjekt python        → Projekt erstellen und Session starten
2. lab-phase Brainstorming       → Ideen-Phase einleiten
3. [Mit Claude/Codex arbeiten]
4. lab-phase Development         → Implementierung beginnen
5. [KI schreibt Code in ./src/]
6. lab-phase Debugging           → Fehler beheben
7. lab-complete MeinProjekt      → Projekt abschließen, Bericht generieren
```

---

## WORKBENCH_BRAIN.md — Wissensbasis

Nach jedem abgeschlossenen Projekt werden Lektionen automatisch in `WORKBENCH_BRAIN.md` gespeichert:
- Maximum **50 Einträge**
- Älteste Einträge rotieren automatisch heraus
- Nur bei Bedarf konsultieren — nicht automatisch laden

---

## Autor

**Alkan Arda**  
Repository: https://github.com/itzEnemy-dot/AI-Lab
