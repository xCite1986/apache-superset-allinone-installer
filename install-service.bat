@echo off
setlocal enabledelayedexpansion
title Apache Superset - Dienst einrichten
cd /d "%~dp0"

REM ===========================================================================
REM  Konfiguration
REM ===========================================================================
set "SERVICE_NAME=ApacheSuperset"
set "SERVICE_DISPLAY=Apache Superset"
set "PORT=8088"

set "VENV_DIR=%~dp0venv"
set "SUPERSET_HOME=%~dp0data"
set "CONFIG_FILE=%~dp0superset_config.py"
set "WAITRESS=%VENV_DIR%\Scripts\waitress-serve.exe"
set "NSSM=%~dp0nssm.exe"

echo(
echo ==================================================
echo    Apache Superset - Windows-Dienst einrichten
echo ==================================================
echo(

REM --- Administratorrechte pruefen ---
net session >nul 2>&1
if errorlevel 1 (
    echo FEHLER: Dieses Skript muss als Administrator ausgefuehrt werden.
    echo Rechtsklick -^> "Als Administrator ausfuehren".
    pause
    exit /b 1
)

REM --- Installation vorhanden? ---
if not exist "%WAITRESS%" (
    echo FEHLER: Superset ist nicht installiert.
    echo Bitte zuerst install-superset.bat ausfuehren.
    pause
    exit /b 1
)

REM ===========================================================================
REM  NSSM (Dienst-Wrapper) bereitstellen
REM ===========================================================================
if not exist "%NSSM%" (
    echo [1/3] Lade NSSM herunter ...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "try { Invoke-WebRequest -Uri 'https://nssm.cc/release/nssm-2.24.zip' -OutFile '%~dp0nssm.zip' -UseBasicParsing; Expand-Archive -Force '%~dp0nssm.zip' '%~dp0nssm_tmp'; Copy-Item '%~dp0nssm_tmp\nssm-2.24\win64\nssm.exe' '%NSSM%' -Force; Remove-Item '%~dp0nssm.zip','%~dp0nssm_tmp' -Recurse -Force } catch { Write-Host $_; exit 1 }"
    if errorlevel 1 (
        echo FEHLER: NSSM konnte nicht heruntergeladen werden.
        echo Bitte nssm.exe ^(win64^) manuell von https://nssm.cc neben dieses
        echo Skript legen und erneut ausfuehren.
        pause
        exit /b 1
    )
) else (
    echo [1/3] NSSM bereits vorhanden.
)

REM ===========================================================================
REM  Dienst (neu) anlegen
REM ===========================================================================
echo [2/3] Richte Dienst "%SERVICE_NAME%" ein ...

REM Falls bereits vorhanden: stoppen und entfernen
"%NSSM%" stop "%SERVICE_NAME%" >nul 2>&1
"%NSSM%" remove "%SERVICE_NAME%" confirm >nul 2>&1

"%NSSM%" install "%SERVICE_NAME%" "%WAITRESS%" --host=0.0.0.0 --port=%PORT% --call "superset.app:create_app"
if errorlevel 1 ( echo FEHLER beim Anlegen des Dienstes. & pause & exit /b 1 )

"%NSSM%" set "%SERVICE_NAME%" DisplayName "%SERVICE_DISPLAY%"
"%NSSM%" set "%SERVICE_NAME%" Description "Apache Superset Business-Intelligence-Plattform"
"%NSSM%" set "%SERVICE_NAME%" AppDirectory "%~dp0"
"%NSSM%" set "%SERVICE_NAME%" Start SERVICE_AUTO_START
"%NSSM%" set "%SERVICE_NAME%" AppStdout "%SUPERSET_HOME%\service.log"
"%NSSM%" set "%SERVICE_NAME%" AppStderr "%SUPERSET_HOME%\service.log"
"%NSSM%" set "%SERVICE_NAME%" AppRotateFiles 1
"%NSSM%" set "%SERVICE_NAME%" AppEnvironmentExtra ^
    "SUPERSET_HOME=%SUPERSET_HOME%" ^
    "SUPERSET_CONFIG_PATH=%CONFIG_FILE%" ^
    "FLASK_APP=superset" ^
    "PYTHONUTF8=1"

REM ===========================================================================
REM  Dienst starten
REM ===========================================================================
echo [3/3] Starte Dienst ...
"%NSSM%" start "%SERVICE_NAME%"

echo(
echo ==================================================
echo    Dienst eingerichtet und gestartet!
echo ==================================================
echo(
echo  Name:   %SERVICE_NAME%  (startet automatisch beim Hochfahren)
echo  URL:    http://localhost:%PORT%
echo  Log:    %SUPERSET_HOME%\service.log
echo(
echo  Steuerung:
echo    net stop  %SERVICE_NAME%
echo    net start %SERVICE_NAME%
echo    Entfernen: uninstall-service.bat
echo(
pause
endlocal
