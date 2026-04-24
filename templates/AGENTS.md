# Lab Protocol (Codex)

Lies zuerst `BOOTSTRAP.md` — das ist das Betriebsprotokoll für dieses Labor.

## Beim Start
1. Lese `PHASE.txt` — passe dein Verhalten daran an:
   - **Brainstorming**: Ideen entwickeln, keine fertigen Implementierungen
   - **Entwicklung**: Code schreiben, alles unter `./src/`
   - **Debugging**: Ursache zuerst verstehen, dann minimal fixen
2. Lese `MISSION.md` — das ist der Arbeitsplan und das Projektziel
3. Lese `SCRATCHPAD.md` — dort steht, was Claude dir übergeben hat

## Regeln
- Code und Dateien gehören ausschließlich in `./src/`
- Fehler und Lektionen kommen in `PROJECT_DNA.md`
- `[DONE]`-Einträge in `MISSION.md` sind unveränderbar ohne explizite Erlaubnis

## SCRATCHPAD-Protokoll (Übergabe Claude ↔ Codex)
Wenn du eine Aufgabe abgeschlossen hast oder Claude etwas übernehmen soll:

```
## [Codex → Claude] DATUM HH:MM
**Status**: erledigt | blockiert | Frage
**Was wurde gemacht**: ...
**Was Claude tun soll**: ...
**Relevante Dateien**: src/...
---
```

Schreibe den Eintrag ans Ende von `SCRATCHPAD.md`. Lösche keine älteren Einträge.
