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
Client nötig). Er wird von der Config automatisch als `cx_Oracle` registriert,
daher wird der Dialekt **`oracle+cx_oracle`** verwendet.

> **Wichtig:** Superset 6.x nutzt SQLAlchemy 1.4, das noch keinen eigenen
> `oracle+oracledb`-Dialekt hat. Verwende deshalb `oracle+cx_oracle` (nicht
> `oracle+oracledb`) – der moderne Treiber läuft trotzdem dahinter.

In Superset: **Einstellungen → Datenbankverbindungen → + Datenbank → SQLAlchemy-URI**.

```
# per Service-Name (empfohlen, z.B. Oracle XE / PDB)
oracle+cx_oracle://BENUTZER:PASSWORT@HOST:1521/?service_name=XEPDB1

# per SID
oracle+cx_oracle://BENUTZER:PASSWORT@HOST:1521/ORCL
```

Beispiel:
```
oracle+cx_oracle://system:geheim@localhost:1521/?service_name=XEPDB1
```

Hinweise:
- Nach dem Treiber-Nachinstallieren Superset **neu starten** (bzw. Dienst neu
  starten), damit Oracle in der Treiber-Liste erscheint.
- Enthält das Passwort Sonderzeichen (`@ : / ?`), müssen diese URL-kodiert werden
  (z. B. `@` → `%40`).
- Sehr alte Oracle-Server (vor 12.1) benötigen den **Thick Mode** mit Oracle
  Instant Client. Dann in `superset_config.py` ergänzen:
  ```python
  import oracledb
  oracledb.init_oracle_client(lib_dir=r"C:\pfad\zu\instantclient")
  ```

## Single Sign-On (SSO) via OpenID Connect

Superset kann sich per **OpenID Connect** an einen Identity Provider anbinden
(Keycloak, Azure AD / Entra ID, Google, Okta, Authentik …). Die Anbindung ist
generisch und wird über eine lokale `superset.env` konfiguriert.

**Einrichtung:**

1. `superset.env.example` nach `superset.env` kopieren.
2. Beim Identity Provider einen **OIDC-Client** (Confidential/Web) anlegen und als
   Redirect-/Callback-URL eintragen:
   ```
   http(s)://<host>:8088/oauth-authorized/oidc
   ```
3. In `superset.env` ausfüllen: `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET` und die
   `OIDC_DISCOVERY_URL` (endet auf `/.well-known/openid-configuration`).
4. Superset neu starten (bzw. Dienst neu starten).

Sobald `OIDC_CLIENT_ID` gesetzt ist, erscheint auf der Login-Seite die
SSO-Anmeldung. Ohne `superset.env` bleibt der normale Benutzer/Passwort-Login
aktiv.

**Rollen-Mapping (optional):** IdP-Gruppen/-Rollen lassen sich auf Superset-Rollen
abbilden. Nutzer in der Gruppe `OIDC_ADMIN_GROUP` werden zu Admins, alle anderen
erhalten `OIDC_DEFAULT_ROLE` (Standard: `Gamma`). Dafür muss der Provider einen
`roles`- bzw. `groups`-Claim liefern (ggf. Scope `groups` in `OIDC_SCOPE`
ergänzen).

> **Wichtig:** `superset.env` enthält Secrets und ist per `.gitignore`
> ausgeschlossen – niemals einchecken. Betrieb hinter HTTPS-Reverse-Proxy:
> `ENABLE_PROXY_FIX = True` in `superset_config.py` aktivieren.

## Deinstallation

1. `uninstall-service.bat` (als Administrator), falls Dienst eingerichtet
2. Ordner `venv\` und `data\` löschen
