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

# ---------------------------------------------------------------------------
# Single Sign-On via OpenID Connect (OIDC)
# ---------------------------------------------------------------------------
# Aktiviert sich automatisch, sobald OIDC_CLIENT_ID gesetzt ist. Die Werte
# werden aus der lokalen Datei "superset.env" geladen (nicht im Repo enthalten,
# siehe superset.env.example). Ohne diese Variablen bleibt der normale
# Benutzer-/Passwort-Login aktiv.
#
# Benoetigt:  OIDC_CLIENT_ID, OIDC_CLIENT_SECRET, OIDC_DISCOVERY_URL
# Redirect-/Callback-URL im Provider eintragen:
#     http(s)://<host>:8088/oauth-authorized/oidc
# ---------------------------------------------------------------------------
try:
    from dotenv import load_dotenv

    load_dotenv(os.path.join(BASE_DIR, "superset.env"))
except Exception:  # dotenv optional; ohne Datei einfach ueberspringen
    pass

OIDC_CLIENT_ID = os.environ.get("OIDC_CLIENT_ID")

if OIDC_CLIENT_ID:
    from flask_appbuilder.security.manager import AUTH_OAUTH
    from superset.security import SupersetSecurityManager

    AUTH_TYPE = AUTH_OAUTH

    # Neue SSO-Nutzer automatisch anlegen ...
    AUTH_USER_REGISTRATION = True
    # ... mit dieser Standardrolle, falls kein Rollen-Mapping greift.
    AUTH_USER_REGISTRATION_ROLE = os.environ.get("OIDC_DEFAULT_ROLE", "Gamma")

    OAUTH_PROVIDERS = [
        {
            "name": "oidc",
            "icon": "fa-key",
            "token_key": "access_token",
            "remote_app": {
                "client_id": OIDC_CLIENT_ID,
                "client_secret": os.environ.get("OIDC_CLIENT_SECRET"),
                # Discovery-URL (.well-known/openid-configuration) -> Endpunkte
                # werden automatisch ermittelt.
                "server_metadata_url": os.environ.get("OIDC_DISCOVERY_URL"),
                "client_kwargs": {
                    "scope": os.environ.get("OIDC_SCOPE", "openid email profile"),
                },
            },
        }
    ]

    # IdP-Gruppen/-Rollen (Claim "roles"/"groups") auf Superset-Rollen abbilden.
    AUTH_ROLES_SYNC_AT_LOGIN = True
    AUTH_ROLES_MAPPING = {
        os.environ.get("OIDC_ADMIN_GROUP", "superset_admins"): ["Admin"],
        os.environ.get("OIDC_USER_GROUP", "superset_users"): ["Gamma"],
    }

    class OIDCSecurityManager(SupersetSecurityManager):
        """Liest die Nutzerdaten aus dem OIDC-userinfo-Endpunkt."""

        def get_oauth_user_info(self, provider, response=None):
            if provider != "oidc":
                return {}
            me = self.appbuilder.sm.oauth_remotes[provider].userinfo()

            # Rollen/Gruppen aus verschiedenen ueblichen Claim-Positionen holen.
            roles = me.get("roles") or me.get("groups") or []
            realm_access = me.get("realm_access") or {}
            if not roles and isinstance(realm_access, dict):
                roles = realm_access.get("roles", [])

            return {
                "username": me.get("preferred_username") or me.get("email"),
                "email": me.get("email"),
                "first_name": me.get("given_name", ""),
                "last_name": me.get("family_name", ""),
                "role_keys": roles,
            }

    CUSTOM_SECURITY_MANAGER = OIDCSecurityManager

    # Hinter Reverse-Proxy (HTTPS-Terminierung) aktivieren:
    # ENABLE_PROXY_FIX = True
