# Apache Superset – All-in-One Installer für Windows

Ein-Klick-Installation von [Apache Superset](https://superset.apache.org/) unter
Windows inklusive optionaler Einrichtung als Windows-Dienst, Oracle-Treiber und
wählbarer Oberflächensprache.

> **Inoffiziell.** Dieses Projekt ist ein Community-Setup und steht in keiner
> Verbindung zur Apache Software Foundation. Apache Superset wird von Windows
> offiziell nicht unterstützt – dieses Setup eignet sich für Einzelplatz-,
> Test- und kleine interne Installationen.

## Schnellstart

1. Repository herunterladen bzw. klonen
2. `install-superset.bat` doppelklicken (Sprache & Zugang werden abgefragt)
3. `start-superset.bat` starten → <http://localhost:8088>
4. Optional: `install-service.bat` als Administrator → läuft als Windows-Dienst

## Dateien

| Datei | Zweck |
|-------|-------|
| `install-superset.bat` | Installiert alles (Python, venv, Superset, DB, Admin-User) |
| `start-superset.bat` | Startet Superset manuell im Vordergrund |
| `install-service.bat` | Richtet Superset als automatisch startenden Windows-Dienst ein (**als Administrator**) |
| `uninstall-service.bat` | Entfernt den Dienst wieder (**als Administrator**) |
| `superset_config.py` | Konfiguration (Datenbank, Schlüssel, Caching …) |

## 1. Installation

Doppelklick auf **`install-superset.bat`**.

Das Skript:
1. installiert Python 3.11 (via `winget`), falls nicht vorhanden
2. erstellt eine isolierte Python-Umgebung unter `venv\`
3. installiert `apache-superset` + `waitress` (WSGI-Server) + `Pillow`
4. erzeugt einen zufälligen Sicherheitsschlüssel (`secret_key.txt`)
5. richtet die Metadaten-Datenbank ein und legt einen Admin-Benutzer an

**Standard-Zugang:** Benutzer `admin` / Passwort `admin` → nach dem ersten Login ändern.
(Änderbar oben in `install-superset.bat` vor dem Ausführen.)

**Sprache:** Der Installer fragt zu Beginn die Standardsprache der Weboberfläche
ab (Deutsch, English, Español, … oder ein beliebiger Sprachcode). Die Auswahl
wird in `language.txt` gespeichert. Zum nachträglichen Ändern einfach den
Sprachcode in `language.txt` anpassen (z. B. `de`, `en`, `fr`) und Superset neu
starten. In der Oberfläche kann oben rechts jederzeit zwischen der gewählten
Sprache und Englisch umgeschaltet werden.

## 2a. Manueller Start

Doppelklick auf **`start-superset.bat`** → http://localhost:8088

## 2b. Als Dienst einrichten

Rechtsklick auf **`install-service.bat`** → **„Als Administrator ausführen"**.

Lädt einmalig `nssm.exe` herunter (Dienst-Wrapper) und registriert den Dienst
`ApacheSuperset`, der automatisch beim Windows-Start läuft.

Steuerung:
```bat
net start ApacheSuperset
net stop ApacheSuperset
```
Log: `data\service.log`

## Hinweise / Grenzen

- **Windows wird von Superset offiziell nicht unterstützt** – dieses Setup nutzt
  Waitress statt Gunicorn und funktioniert für Einzelplatz-/Testbetrieb gut.
- Standardmäßig **SQLite** als Metadaten-DB (keine Extra-Software nötig).
  Für Mehrbenutzer-/Produktivbetrieb in `superset_config.py` auf **PostgreSQL**
  umstellen.
- Asynchrone Abfragen, Alerts & Reports benötigen zusätzlich **Redis + Celery**
  (hier nicht enthalten, für Basisbetrieb nicht nötig).
- Für Zugriff über die Firewall ggf. Port 8088 freigeben.
- Beispiel-Dashboards nachladen (optional):
  ```bat
  venv\Scripts\superset.exe load_examples
  ```

## Oracle-Datenbank anbinden

Der Treiber `python-oracledb` ist installiert (Thin Mode – **kein** Oracle Instant
Client nötig).

In Superset: **Settings → Database Connections → + Database → SQLAlchemy URI**.
Verbindungs-URI (SQLAlchemy-Dialekt `oracle+oracledb`):

```
# per Service-Name (empfohlen, z.B. Oracle XE / PDB)
oracle+oracledb://BENUTZER:PASSWORT@HOST:1521/?service_name=XEPDB1

# per SID
oracle+oracledb://BENUTZER:PASSWORT@HOST:1521/ORCL
```

Beispiel lokal:
```
oracle+oracledb://system:geheim@localhost:1521/?service_name=XEPDB1
```

Hinweise:
- Nach dem Treiber-Nachinstallieren Superset **neu starten** (bzw. Dienst neu
  starten), damit Oracle in der Treiber-Liste erscheint.
- Sehr alte Oracle-Server (vor 12.1) benötigen den **Thick Mode** mit Oracle
  Instant Client. Dann in `superset_config.py` ergänzen:
  ```python
  import oracledb
  oracledb.init_oracle_client(lib_dir=r"C:\pfad\zu\instantclient")
  ```

## Deinstallation

1. `uninstall-service.bat` (als Administrator), falls Dienst eingerichtet
2. Ordner `venv\` und `data\` löschen
