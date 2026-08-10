@echo off
setlocal
if "%~1"=="" (
    echo Please drag a target folder onto this file.
    pause
    exit /b 1
)
set "SCRIPT_DIR=%~dp0..\src"
if not exist "%SCRIPT_DIR%\Remove-XxSubtitled.ps1" set "SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\Remove-XxSubtitled.ps1" -TargetPath "%~1"
if errorlevel 1 pause
