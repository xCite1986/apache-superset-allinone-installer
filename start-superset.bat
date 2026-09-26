@echo off
setlocal
title Apache Superset
cd /d "%~dp0"

set "PORT=8088"
set "VENV_DIR=%~dp0venv"
set "SUPERSET_HOME=%~dp0data"
set "SUPERSET_CONFIG_PATH=%~dp0superset_config.py"
set "FLASK_APP=superset"
set "PYTHONUTF8=1"

if not exist "%VENV_DIR%\Scripts\waitress-serve.exe" (
    echo Superset ist noch nicht installiert. Bitte zuerst install-superset.bat ausfuehren.
    pause
    exit /b 1
)

echo Starte Apache Superset auf http://localhost:%PORT%  (Strg+C zum Beenden)
echo(
"%VENV_DIR%\Scripts\waitress-serve.exe" --host=0.0.0.0 --port=%PORT% --call "superset.app:create_app"

endlocal
