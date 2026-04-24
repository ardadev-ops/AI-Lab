# Lab Protocol

Lies zuerst `BOOTSTRAP.md` — das ist das Betriebsprotokoll für dieses Labor.

## Beim Start
1. Lese `PHASE.txt` — passe dein Verhalten daran an
2. Ist `MISSION.md` noch leer oder nur ein Platzhalter? Dann frage nach dem Projektziel und schreibe es rein
3. Erstelle einen Arbeitsplan mit Confidence-Score (Regeln stehen in BOOTSTRAP.md)
4. Schreibe den Plan in `MISSION.md`

## Regeln
- Code und Dateien gehören ausschließlich in `./src/`
- Fehler und Lektionen kommen in `PROJECT_DNA.md`
- `[DONE]`-Einträge in `MISSION.md` sind unveränderbar ohne explizite Erlaubnis

## SCRATCHPAD-Protokoll (Übergabe Claude ↔ Codex)
Lese `SCRATCHPAD.md` beim Start — dort steht, was Codex dir übergeben hat.
Wenn du eine Aufgabe abgeschlossen hast oder Codex etwas übernehmen soll:

```
## [Claude → Codex] DATUM HH:MM
**Status**: erledigt | blockiert | Frage
**Was wurde gemacht**: ...
**Was Codex tun soll**: ...
**Relevante Dateien**: src/...
---
```

Schreibe den Eintrag ans Ende von `SCRATCHPAD.md`. Lösche keine älteren Einträge.
