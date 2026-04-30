# Lab Protocol (Codex)

Lies zuerst `BOOTSTRAP.md` — das ist das Betriebsprotokoll für dieses Labor.

## Beim Start
1. Lese `PHASE.txt` — passe dein Verhalten daran an:
   - **Brainstorming**: Ideen entwickeln, keine fertigen Implementierungen
   - **Entwicklung**: Code schreiben, alles unter `./src/`
   - **Debugging**: Lies auch `PROJECT_DNA.md`, Ursache zuerst verstehen, dann minimal fixen
2. Lese `MISSION.md` — das ist der Arbeitsplan und das Projektziel
3. **SCRATCHPAD.md** — lies die Datei nur wenn echte Einträge vorhanden sind (Zeilen die mit `## [` beginnen). Zeigt die Datei nur das leere Format-Template: überspringe sie vollständig.

## Regeln
- Code und Dateien gehören ausschließlich in `./src/`
- Fehler und Lektionen kommen in `PROJECT_DNA.md`
- `[DONE]`-Einträge in `MISSION.md` sind unveränderbar ohne explizite Erlaubnis

## SCRATCHPAD-Protokoll (Übergabe Claude ↔ Codex)
Wenn du eine Aufgabe abgeschlossen hast oder Claude etwas übernehmen soll, schreibe ans Ende von `SCRATCHPAD.md`:

```
## [Codex → Claude] DATUM HH:MM
**Status**: erledigt | blockiert | Frage
**Was wurde gemacht**: ...
**Was Claude tun soll**: ...
**Relevante Dateien**: src/...
---
```

Lösche keine Einträge — Rotation erfolgt automatisch durch den Stop-Hook.

## Kollaborations-Protokoll (Shared Files)
Falls Claude gleichzeitig mit dir an geteilten Dateien arbeitet (MISSION.md, SCRATCHPAD.md, etc.):

1. **Vor dem Schreiben**: Prüfe ob die Datei bereits gelockt ist.
   - Dateilock prüfen: Existiert `.lab/state/locks/<datei>.lock`?
   - Ja → Warte ~3 Sekunden und versuche es erneut. Falls >10s: notiere im SCRATCHPAD und fahre fort.
   - Nein → Weitergabe zu Schritt 2.

2. **Lock setzen** bevor du schreibst:
   - Erstelle `.lab/state/locks/<datei>.lock` mit folgendem JSON-Inhalt:
     ```json
     { "agent": "Codex", "file": "MISSION.md", "timestamp": "2026-04-26T14:23:01" }
     ```

3. **Schreibe die Datei** (deine Änderungen).

4. **Lock entfernen** sofort nach dem Schreiben:
   - Lösche die `.lock`-Datei.

**Falls Konflikt erkannt wird**: Im `.lab/state/conflicts/` Verzeichnis erscheint eine `.conflict`-Datei. 
Der Lab-Watcher zeigt diese im `COLLAB Conflicts`-Pane (Zellij rechts). 
Der User kann dann `lab-resolve [dateiname]` aufrufen um zu mergen.

## MISSION.md — Live-Arbeitsplan
Halte MISSION.md während der Arbeit aktuell:
- Task starten   -> [~] In Arbeit setzen
- Task fertig    -> [x] Erledigt, nächsten aus Next Up holen
- Neuer Schritt  -> unter Next Up eintragen
- Erkenntnis     -> kurz unter Notizen

Maximal 3 Eintraege pro Sektion. Token-freundlich: ein Satz pro Eintrag.

## Auto-Learning in WORKBENCH_BRAIN.md
Wenn du während dieses Projekts auf etwas Wissenswertiges stößt — einen Bug-Pattern, ein Lösungsmuster, ein wichtiges Setup-Detail — schreibe es automatisch ins WORKBENCH_BRAIN.md:

```
[#tag] Titel | Kurzer Kontext | Was zu tun
```

**Tags:** `#bug`, `#pattern`, `#tooling`, `#workflow`

**Beispiel:**
```
[#pattern] EF Core AsNoTracking | .NET Database Queries | Immer .AsNoTracking() bei Read-only-Queries — 40% weniger Overhead
```

Dies ist nicht nur für `lab-complete`, sondern während des ganzen Projekts. Schreib die Lektion ans Ende von `$env:LAB_HOME\WORKBENCH_BRAIN.md`.
