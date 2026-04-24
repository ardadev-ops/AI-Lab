# Design: Mission-Pane & Token-Manager Verbesserung
_Datum: 2026-04-24_

---

## Ziel

Zwei Zellij-Panes verbessern:
1. **MISSION To-Do Liste** — wird von AIs automatisch gepflegt statt nur angezeigt
2. **Token Manager** — zeigt nur die aktuelle Session, kompakt mit Live-Rate-Status

---

## Sektion 1: MISSION To-Do Liste

### Problem
MISSION.md wird beim Start von Claude/Codex einmalig befüllt, danach aber nicht mehr aktiv gepflegt. Die AIs schreiben keinen Fortschritt rein während sie arbeiten.

### Lösung

**A) CLAUDE.md + AGENTS.md — neue Verhaltensregel**

Beide Templates bekommen einen neuen Abschnitt `## MISSION.md — Live-Arbeitsplan`:

```
## MISSION.md — Live-Arbeitsplan
Halte MISSION.md während der Arbeit aktuell:
- Task starten   -> [~] In Arbeit setzen
- Task fertig    -> [x] Erledigt, nächsten aus Next Up holen
- Neuer Schritt  -> unter Next Up eintragen
- Erkenntnis     -> kurz unter Notizen

Maximal 3 Eintraege pro Sektion. Token-freundlich: ein Satz pro Eintrag.
```

Gilt für: `templates/CLAUDE.md`, `templates/AGENTS.md` und alle bestehenden quickstart-Instanzen.

**B) monitor.ps1 — farbiges Rendering**

`Render-Mission` bekommt eine Zeilen-by-Zeilen Auswertung:

| Muster | Farbe |
|--------|-------|
| `- [ ]` | Gray (offen) |
| `- [~]` | Yellow (in Arbeit) |
| `- [x]` | Green (erledigt) |
| `## ...` | Cyan (Sektion) |
| Alles andere | White |

**MISSION.md-Format bleibt identisch** — kein Breaking Change, kein Umstrukturieren.

### Dateien die sich ändern
- `templates/CLAUDE.md`
- `templates/AGENTS.md`
- `quickstart/quick-1/CLAUDE.md`, `quick-2/CLAUDE.md`, `join/CLAUDE.md`
- `quickstart/quick-1/AGENTS.md`, `quick-2/AGENTS.md`, `join/AGENTS.md`
- `monitor.ps1` — Funktion `Render-Mission`

---

## Sektion 2: Token Manager

### Problem
- USAGE-Pane zeigt akkumulierte Tokens aller bisherigen Sessions, nicht die aktuelle
- Kein Gefühl für Tempo (viel oder wenig gerade)
- Format ist zu lang und wächst mit USAGE.md

### Lösung

**A) SESSION_START.txt — Session-Anker**

`start-ai` und `lab [Name]` schreiben beim Start:
```
SESSION_START.txt  →  2026-04-24T14:32:07
```

Ins Projektverzeichnis. Überschreibt bei jedem neuen Start.

**B) monitor.ps1 — Render-Usage neu**

Liest JSONL-Einträge, filtert auf `timestamp >= SESSION_START`. Berechnet:
- **Gesamt-Tokens** dieser Session (Input + Output + CacheRead + CacheCreate)
- **Rate** = Tokens in den letzten 5 Minuten
- **Status** basierend auf Rate:
  - `NIEDRIG`  → < 500 Tokens/5min (grün)
  - `MITTEL`   → 500–3000 Tokens/5min (gelb)
  - `HOCH`     → > 3000 Tokens/5min (rot)

**Ausgabeformat (8 Zeilen fix):**
```
TOKEN MANAGER  |  quick-1  |  Phase: Brainstorming
Seit: 14:32

Tokens:   12.450   Input: 8.2k / Output: 4.2k
Cache:     3.100   gespart
Rate:      2.3k / 5min
Status:   [ MITTEL ]

Letzte Aktivitaet: 14:47
```

**C) Render-Usage zeigt USAGE.md nicht mehr**

Der Session-Log (USAGE.md-Inhalt) wird aus dem USAGE-Pane entfernt. Das Pane wird rein zum Token-Dashboard. USAGE.md wird weiterhin von `stop_hook.ps1` befüllt — nur nicht mehr live angezeigt.

### Dateien die sich ändern
- `shell/profile.ps1` — `start-ai`: schreibt `SESSION_START.txt`
- `lab.ps1` — schreibt `SESSION_START.txt` beim Öffnen
- `monitor.ps1` — Funktion `Render-Usage` komplett neu
- `monitor.ps1` — Hilfsfunktion `Get-SessionTokens` (filtert nach SESSION_START)
- `monitor.ps1` — Hilfsfunktion `Get-TokenRate` (letzte 5 Min)

---

## Nicht in Scope

- Codex/Gemini Token-Tracking (kein bekanntes JSONL-Format)
- Kostenschätzung in Dollar (kein hartes Budget gewünscht)
- Änderungen am MISSION.md-Format selbst

---

## Erfolg

- AIs (Claude + Codex) updaten MISSION.md aktiv während der Arbeit ohne extra Prompt
- Token-Pane zeigt nach Sessionstart sofort Werte, bleibt 8 Zeilen
- Kein Context-Overhead: MISSION.md-Regel ist 5 Zeilen, SESSION_START.txt ist 1 Zeile
