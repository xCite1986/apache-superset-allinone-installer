import os

# Basisverzeichnis dieser Konfigurationsdatei
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Datenverzeichnis (Metadaten-DB, Cache, Logs). Wird vom Installer gesetzt.
SUPERSET_HOME = os.environ.get("SUPERSET_HOME", os.path.join(BASE_DIR, "data"))

# ---------------------------------------------------------------------------
# Sicherheitsschluessel
# Wird beim ersten Installationslauf zufaellig erzeugt und in secret_key.txt
# gespeichert. NICHT weitergeben und NICHT aendern (sonst sind gespeicherte
# Zugangsdaten/Sessions ungueltig).
# ---------------------------------------------------------------------------
_secret_file = os.path.join(BASE_DIR, "secret_key.txt")
if os.path.exists(_secret_file):
    with open(_secret_file, "r", encoding="utf-8") as _f:
        SECRET_KEY = _f.read().strip()
else:
    # Fallback (sollte im Normalbetrieb nie greifen)
    SECRET_KEY = "CHANGE_ME_INSECURE_DEV_KEY"

# ---------------------------------------------------------------------------
# Metadaten-Datenbank
# Standard: SQLite (einfach, kein Extra-Setup). Fuer Produktion / mehrere
# Nutzer PostgreSQL empfohlen, z.B.:
#   SQLALCHEMY_DATABASE_URI = "postgresql+psycopg2://user:pass@localhost/superset"
# ---------------------------------------------------------------------------
SQLALCHEMY_DATABASE_URI = "sqlite:///" + os.path.join(SUPERSET_HOME, "superset.db").replace("\\", "/")

# ---------------------------------------------------------------------------
# Allgemeine Einstellungen
# ---------------------------------------------------------------------------
ROW_LIMIT = 5000

# Caching im Arbeitsspeicher (einfacher Standard, kein Redis noetig).
CACHE_CONFIG = {
    "CACHE_TYPE": "SimpleCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
}

# Kartenmaterial / Feature Flags nach Bedarf hier ergaenzen.
FEATURE_FLAGS = {
    "EMBEDDED_SUPERSET": True,
}

# WTF CSRF aktiv lassen (Sicherheit).
WTF_CSRF_ENABLED = True

# ---------------------------------------------------------------------------
# Sprache / Lokalisierung
# Die Standardsprache wird beim Setup in language.txt festgelegt.
# Umschalten ist zur Laufzeit oben rechts im Menue moeglich.
# ---------------------------------------------------------------------------
_LANG_META = {
    "en": {"flag": "us", "name": "English"},
    "de": {"flag": "de", "name": "German"},
    "es": {"flag": "es", "name": "Spanish"},
    "fr": {"flag": "fr", "name": "French"},
    "it": {"flag": "it", "name": "Italian"},
    "nl": {"flag": "nl", "name": "Dutch"},
    "pt": {"flag": "pt", "name": "Portuguese"},
    "pt_BR": {"flag": "br", "name": "Portuguese (Brazil)"},
    "ru": {"flag": "ru", "name": "Russian"},
    "pl": {"flag": "pl", "name": "Polish"},
    "tr": {"flag": "tr", "name": "Turkish"},
    "uk": {"flag": "uk", "name": "Ukrainian"},
    "sk": {"flag": "sk", "name": "Slovak"},
    "sl": {"flag": "si", "name": "Slovenian"},
    "ca": {"flag": "es", "name": "Catalan"},
    "ar": {"flag": "sa", "name": "Arabic"},
    "fa": {"flag": "ir", "name": "Persian"},
    "ja": {"flag": "jp", "name": "Japanese"},
    "ko": {"flag": "kr", "name": "Korean"},
    "zh": {"flag": "cn", "name": "Chinese"},
    "zh_TW": {"flag": "tw", "name": "Chinese (Taiwan)"},
    "mi": {"flag": "nz", "name": "Maori"},
}

_lang_file = os.path.join(BASE_DIR, "language.txt")
_default_lang = "en"
if os.path.exists(_lang_file):
    with open(_lang_file, "r", encoding="utf-8") as _f:
        _sel = _f.read().strip()
    if _sel in _LANG_META:
        _default_lang = _sel

BABEL_DEFAULT_LOCALE = _default_lang
BABEL_DEFAULT_FOLDER = "superset/translations"

# Auswaehlbare Sprachen: gewaehlte Standardsprache + Englisch als Rueckfall.
_enabled = {_default_lang, "en"}
LANGUAGES = {code: _LANG_META[code] for code in _LANG_META if code in _enabled}
