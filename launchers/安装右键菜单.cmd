@echo off
setlocal
set "SCRIPT_DIR=%~dp0..\src"
if not exist "%SCRIPT_DIR%\Install.ps1" set "SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\Install.ps1"
if errorlevel 1 pause
