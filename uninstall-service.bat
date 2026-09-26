@echo off
setlocal
title Apache Superset - Dienst entfernen
cd /d "%~dp0"

set "SERVICE_NAME=ApacheSuperset"
set "NSSM=%~dp0nssm.exe"

net session >nul 2>&1
if errorlevel 1 (
    echo FEHLER: Bitte als Administrator ausfuehren.
    pause
    exit /b 1
)

echo Entferne Dienst "%SERVICE_NAME%" ...
if exist "%NSSM%" (
    "%NSSM%" stop "%SERVICE_NAME%" >nul 2>&1
    "%NSSM%" remove "%SERVICE_NAME%" confirm
) else (
    sc stop "%SERVICE_NAME%" >nul 2>&1
    sc delete "%SERVICE_NAME%"
)

echo(
echo Dienst entfernt. Daten und venv bleiben erhalten.
pause
endlocal
