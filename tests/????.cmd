@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-FilenameSuffixCleaner.ps1"
if errorlevel 1 goto :end
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-ReleaseWorkflow.ps1"
:end
pause
