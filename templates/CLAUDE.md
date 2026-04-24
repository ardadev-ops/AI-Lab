# Lab Protocol

Lies zuerst `BOOTSTRAP.md` — das ist das Betriebsprotokoll für dieses Labor.

## Beim Start
1. Lese `PHASE.txt` — passe dein Verhalten daran an:
   - **Brainstorming**: Ideen entwickeln, keine fertigen Implementierungen
   - **Entwicklung**: Code schreiben, alles unter `./src/`
   - **Debugging**: Lies auch `PROJECT_DNA.md`, dann minimal fixen
2. **SCRATCHPAD.md** — lies die Datei nur wenn echte Einträge vorhanden sind (Zeilen die mit `## [` beginnen). Zeigt die Datei nur das leere Format-Template: überspringe sie vollständig.
3. Ist `MISSION.md` noch leer oder nur ein Platzhalter? Dann frage nach dem Projektziel und schreibe es rein.
4. Erstelle einen Arbeitsplan mit Confidence-Score (Regeln stehen in BOOTSTRAP.md).
5. Schreibe den Plan in `MISSION.md`.

## Regeln
- Code und Dateien gehören ausschließlich in `./src/`
- Fehler und Lektionen kommen in `PROJECT_DNA.md`
- `[DONE]`-Einträge in `MISSION.md` sind unveränderbar ohne explizite Erlaubnis

## SCRATCHPAD-Protokoll (Übergabe Claude ↔ Codex)
Wenn du eine Aufgabe abgeschlossen hast oder Codex etwas übernehmen soll, schreibe ans Ende von `SCRATCHPAD.md`:

```
## [Claude → Codex] DATUM HH:MM
**Status**: erledigt | blockiert | Frage
**Was wurde gemacht**: ...
**Was Codex tun soll**: ...
**Relevante Dateien**: src/...
---
```

Lösche keine Einträge — Rotation erfolgt automatisch durch den Stop-Hook.

## MISSION.md — Live-Arbeitsplan
Halte MISSION.md während der Arbeit aktuell:
- Task starten   -> [~] In Arbeit setzen
- Task fertig    -> [x] Erledigt, nächsten aus Next Up holen
- Neuer Schritt  -> unter Next Up eintragen
- Erkenntnis     -> kurz unter Notizen

Maximal 3 Eintraege pro Sektion. Token-freundlich: ein Satz pro Eintrag.

## Werkbank-Wissen (optional)
Im Lab-Home-Verzeichnis liegt `WORKBENCH_BRAIN.md` mit destillierten Lektionen aus abgeschlossenen Projekten.
Pfad ermitteln: PowerShell-Variable `$env:LAB_HOME`, dann `WORKBENCH_BRAIN.md` darin lesen.
Nur konsultieren wenn für das aktuelle Projekt relevant — nicht automatisch beim Start laden.
