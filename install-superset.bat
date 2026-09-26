@echo off
setlocal enabledelayedexpansion
title Apache Superset - Ein-Klick-Installer
cd /d "%~dp0"

REM ===========================================================================
REM  Konfiguration (bei Bedarf anpassen)
REM ===========================================================================
set "PORT=8088"
set "ADMIN_USER=admin"
set "ADMIN_PASS=admin"
set "ADMIN_FIRST=Superset"
set "ADMIN_LAST=Admin"
set "ADMIN_EMAIL=admin@superset.local"

REM Verzeichnisse
set "VENV_DIR=%~dp0venv"
set "SUPERSET_HOME=%~dp0data"
set "CONFIG_FILE=%~dp0superset_config.py"

REM Umgebung fuer die Superset-CLI
set "SUPERSET_CONFIG_PATH=%CONFIG_FILE%"
set "FLASK_APP=superset"
set "PYTHONUTF8=1"

echo(
echo ==================================================
echo    Apache Superset - Installation
echo ==================================================
echo(

if not exist "%SUPERSET_HOME%" mkdir "%SUPERSET_HOME%"

REM ===========================================================================
REM  Sprachauswahl fuer die Weboberflaeche
REM ===========================================================================
echo Bitte Standardsprache der Weboberflaeche waehlen:
echo    [1] Deutsch
echo    [2] English
echo    [3] Espanol (Spanisch)
echo    [4] Francais (Franzoesisch)
echo    [5] Italiano (Italienisch)
echo    [6] Nederlands (Niederlaendisch)
echo    [0] Andere (Sprachcode manuell eingeben)
echo(
set "LANGCHOICE="
set /p "LANGCHOICE=Auswahl [1]: "
if not defined LANGCHOICE set "LANGCHOICE=1"

set "LANGCODE=de"
if "%LANGCHOICE%"=="1" set "LANGCODE=de"
if "%LANGCHOICE%"=="2" set "LANGCODE=en"
if "%LANGCHOICE%"=="3" set "LANGCODE=es"
if "%LANGCHOICE%"=="4" set "LANGCODE=fr"
if "%LANGCHOICE%"=="5" set "LANGCODE=it"
if "%LANGCHOICE%"=="6" set "LANGCODE=nl"
if "%LANGCHOICE%"=="0" (
    echo Verfuegbar: en de es fr it nl pt pt_BR ru pl tr uk sk sl ca ar fa ja ko zh zh_TW mi
    set /p "LANGCODE=Sprachcode: "
)

> "%~dp0language.txt" echo !LANGCODE!
echo      Standardsprache gesetzt: !LANGCODE!
echo(

REM ===========================================================================
REM  1) Python 3.11 sicherstellen
REM ===========================================================================
echo [1/6] Pruefe Python 3.11 ...
set "BASEPY="
set "BASEARG="

py -3.11 --version >nul 2>&1 && ( set "BASEPY=py" & set "BASEARG=-3.11" )

if not defined BASEPY (
    echo      Python 3.11 nicht gefunden - Installation via winget ...
    winget install -e --id Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo(
        echo FEHLER: Automatische Python-Installation fehlgeschlagen.
        echo Bitte Python 3.11 manuell von https://www.python.org installieren
        echo und dieses Skript erneut ausfuehren.
        pause
        exit /b 1
    )
    py -3.11 --version >nul 2>&1 && ( set "BASEPY=py" & set "BASEARG=-3.11" )
)

if not defined BASEPY (
    if exist "%LocalAppData%\Programs\Python\Python311\python.exe" (
        set "BASEPY=%LocalAppData%\Programs\Python\Python311\python.exe"
        set "BASEARG="
    )
)

if not defined BASEPY (
    echo FEHLER: Python 3.11 konnte nicht gefunden werden. Bitte Terminal neu
    echo starten und Skript erneut ausfuehren.
    pause
    exit /b 1
)
echo      Python OK.

REM ===========================================================================
REM  2) Virtuelle Umgebung erstellen
REM ===========================================================================
echo [2/6] Erstelle virtuelle Umgebung ...
if not exist "%VENV_DIR%\Scripts\python.exe" (
    "%BASEPY%" %BASEARG% -m venv "%VENV_DIR%"
    if errorlevel 1 ( echo FEHLER beim Erstellen der venv. & pause & exit /b 1 )
)
set "PYEXE=%VENV_DIR%\Scripts\python.exe"
set "SUPERSET_EXE=%VENV_DIR%\Scripts\superset.exe"
echo      venv OK.

REM ===========================================================================
REM  3) Pakete installieren
REM ===========================================================================
echo [3/6] Aktualisiere pip und installiere Superset (kann einige Minuten dauern) ...
"%PYEXE%" -m pip install --upgrade pip setuptools wheel
if errorlevel 1 ( echo FEHLER bei pip-Upgrade. & pause & exit /b 1 )

"%PYEXE%" -m pip install "apache-superset" waitress Pillow rich cachetools "flask-caching<2.2" oracledb
if errorlevel 1 (
    echo FEHLER bei der Installation von apache-superset.
    pause
    exit /b 1
)
echo      Pakete OK.

REM ===========================================================================
REM  4) Geheimschluessel erzeugen (nur beim ersten Mal)
REM ===========================================================================
echo [4/6] Sicherheitsschluessel ...
if not exist "%~dp0secret_key.txt" (
    "%PYEXE%" -c "import secrets;open(r'%~dp0secret_key.txt','w',encoding='utf-8').write(secrets.token_urlsafe(42))"
    echo      Neuer Schluessel erzeugt: secret_key.txt
) else (
    echo      Vorhandener Schluessel wird verwendet.
)

REM ===========================================================================
REM  5) Datenbank initialisieren + Admin anlegen
REM ===========================================================================
echo [5/6] Initialisiere Metadaten-Datenbank ...
"%SUPERSET_EXE%" db upgrade
if errorlevel 1 ( echo FEHLER bei 'superset db upgrade'. & pause & exit /b 1 )

echo      Lege Admin-Benutzer an ( %ADMIN_USER% ) ...
"%SUPERSET_EXE%" fab create-admin --username "%ADMIN_USER%" --firstname "%ADMIN_FIRST%" --lastname "%ADMIN_LAST%" --email "%ADMIN_EMAIL%" --password "%ADMIN_PASS%"

echo      Initialisiere Rollen und Rechte ...
"%SUPERSET_EXE%" init
if errorlevel 1 ( echo FEHLER bei 'superset init'. & pause & exit /b 1 )

REM ===========================================================================
REM  6) Fertig
REM ===========================================================================
echo(
echo ==================================================
echo    Installation abgeschlossen!
echo ==================================================
echo(
echo  Start manuell:      start-superset.bat
echo  Als Dienst:         install-service.bat  (als Administrator)
echo(
echo  URL:      http://localhost:%PORT%
echo  Benutzer: %ADMIN_USER%
echo  Passwort: %ADMIN_PASS%    ^<-- unbedingt aendern!
echo(
pause
endlocal
