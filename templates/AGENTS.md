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
