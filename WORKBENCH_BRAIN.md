# WORKBENCH BRAIN
Destillierte Lektionen aus abgeschlossenen Projekten. Max 50 Einträge, älteste rotieren automatisch raus.
Nur bei Bedarf konsultieren — nicht automatisch laden.

## Format
Jede Lektion = `[TAG] Titel | Kontext | Was zu tun`

### Tags
- `#bug` — häufige Fehler, Fallstricke
- `#pattern` — bewährte Lösungsmuster, Best Practices  
- `#tooling` — Setup, Tools, Konfiguration
- `#workflow` — Prozesse, Agent-Koordination

## Lektionen

[#bug] SESSION_START-Filtering in Token-Ausgabe | Lab Monitor Dashboard | SESSION_START wird oft zu früh gesetzt (bevor erste Claude-Anfrage). Filter mit `$ts -lt $sessionStart` führt zu 0 Entries. Lösung: Dashboard sollte 0-Werte sauber formatieren statt "keine Daten noch" — gibt Signal, dass Session läuft aber keine Anfragen gemacht wurden.

---
